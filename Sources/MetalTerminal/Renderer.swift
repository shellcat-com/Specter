import AppKit
import MetalKit
import TerminalCore
import TextLayout

private struct Vertex {
  var position: SIMD2<Float>
  var uv: SIMD2<Float>
  var color: SIMD4<Float>
}
private struct AtlasEntry {
  let page: Int
  let rect: CGRect
}

@MainActor
public final class Renderer: NSObject, MTKViewDelegate {
  public var snapshot: ScreenSnapshot?
  public var theme = Theme.builtins[0]
  public var scrollOffset = 0
  public var selection: (Position, Position)?
  public var cursorVisible = true
  public var cursorStyle = "block"
  public var ligatures = false
  public var searchHit: Position?
  public private(set) var rasterizer: GlyphRasterizer
  public private(set) var frames = 0
  public var lastInputTimestamp: CFTimeInterval?
  private var cpuFrameTimes: [Double] = []
  private var presentationLatencies: [Double] = []
  public func performanceReport() -> [String: Any] {
    func summary(_ values: [Double]) -> [String: Any] {
      let sorted = values.sorted()
      guard !sorted.isEmpty else { return ["status": "not measured"] }
      return [
        "samples": sorted.count, "median_ms": sorted[sorted.count / 2],
        "p95_ms": sorted[min(sorted.count - 1, Int(Double(sorted.count) * 0.95))],
      ]
    }
    return [
      "frames": frames, "rows_redrawn": rowsRedrawn, "atlas_hits": atlasHits,
      "atlas_misses": atlasMisses, "atlas_resets": atlasResets,
      "atlas_bytes": pages.count * atlasSize * atlasSize * 4,
      "cpu_frame_encoding": summary(cpuFrameTimes),
      "input_event_to_presentation_callback": summary(presentationLatencies),
      "note":
        "Software timestamps; excludes keyboard hardware and physical display latency. No terminal contents recorded.",
    ]
  }
  public private(set) var atlasMisses = 0
  public private(set) var atlasHits = 0
  public private(set) var atlasResets = 0
  private let device: MTLDevice
  private let queue: MTLCommandQueue
  private let pipeline: MTLRenderPipelineState
  private var pages: [MTLTexture] = []
  private var cache: [GlyphKey: AtlasEntry] = [:]
  private var x = 1, y = 1, shelfHeight = 0
  private let atlasSize = 2048
  private var backing: MTLTexture?
  private var previousLines: [ScreenLine] = []
  private var previousSignature = ""
  private var previousCursor: Position?
  private var previousCursorVisible = false
  public private(set) var rowsRedrawn = 0
  private let white: MTLTexture
  public init(
    device: MTLDevice, fontName: String = "Menlo", fontSize: CGFloat = 14, scale: CGFloat = 2
  ) throws {
    self.device = device
    guard let queue = device.makeCommandQueue() else { throw RenderError.unavailable }
    self.queue = queue
    rasterizer = GlyphRasterizer(fontName: fontName, size: fontSize, scale: scale)
    let bundle = TerminalResources.bundle
    let library: MTLLibrary
    if let url = bundle.url(forResource: "Shaders", withExtension: "metal") {
      library = try device.makeLibrary(
        source: String(contentsOf: url, encoding: .utf8), options: nil)
    } else {
      // Xcode compiles processed Metal resources into default.metallib.
      library = try device.makeDefaultLibrary(bundle: bundle)
    }
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.vertexFunction = library.makeFunction(name: "terminalVertex")
    descriptor.fragmentFunction = library.makeFunction(name: "terminalFragment")
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    descriptor.colorAttachments[0].isBlendingEnabled = true
    descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
    descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
    descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rgba8Unorm, width: 1, height: 1, mipmapped: false)
    textureDescriptor.storageMode = .shared
    guard let white = device.makeTexture(descriptor: textureDescriptor) else {
      throw RenderError.unavailable
    }
    self.white = white
    var pixel: UInt32 = 0xFFFF_FFFF
    white.replace(
      region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, withBytes: &pixel, bytesPerRow: 4)
    super.init()
  }
  public enum RenderError: Error { case unavailable }
  public func configure(fontName: String, size: CGFloat, scale: CGFloat) {
    rasterizer = GlyphRasterizer(fontName: fontName, size: size, scale: scale)
    resetAtlas()
  }
  private func resetAtlas() {
    // Old textures remain retained by their command buffers until GPU completion.
    pages.removeAll()
    cache.removeAll()
    x = 1
    y = 1
    shelfHeight = 0
    atlasResets += 1
    previousLines.removeAll()
  }
  private func entry(for cell: Cell) -> AtlasEntry? {
    let key = GlyphKey(cell: cell, ligatures: ligatures)
    if let hit = cache[key] {
      atlasHits += 1
      return hit
    }
    guard let image = rasterizer.rasterize(key), image.width + 2 < atlasSize,
      image.height + 2 < atlasSize
    else { return nil }
    if x + image.width + 1 >= atlasSize {
      x = 1
      y += shelfHeight + 1
      shelfHeight = 0
    }
    if pages.isEmpty || y + image.height + 1 >= atlasSize {
      guard pages.count < 4 else { return nil }
      let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm, width: atlasSize, height: atlasSize, mipmapped: false)
      descriptor.storageMode = .shared
      descriptor.usage = .shaderRead
      guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
      pages.append(texture)
      x = 1
      y = 1
      shelfHeight = 0
    }
    guard let bytes = image.dataProvider?.data, let pointer = CFDataGetBytePtr(bytes) else {
      return nil
    }
    let rect = CGRect(x: x, y: y, width: image.width, height: image.height)
    pages[pages.count - 1].replace(
      region: MTLRegionMake2D(x, y, image.width, image.height), mipmapLevel: 0, withBytes: pointer,
      bytesPerRow: image.bytesPerRow)
    let result = AtlasEntry(page: pages.count - 1, rect: rect)
    x += image.width + 1
    shelfHeight = max(shelfHeight, image.height)
    cache[key] = result
    atlasMisses += 1
    return result
  }
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
  public func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable, let pass = view.currentRenderPassDescriptor,
      let buffer = queue.makeCommandBuffer()
    else { return }
    let start = CACurrentMediaTime()
    encode(pass: pass, command: buffer, size: view.bounds.size)
    cpuFrameTimes.append((CACurrentMediaTime() - start) * 1000)
    if cpuFrameTimes.count > 1000 { cpuFrameTimes.removeFirst() }
    if let input = lastInputTimestamp {
      lastInputTimestamp = nil
      drawable.addPresentedHandler { [weak self] _ in
        let elapsed = (CACurrentMediaTime() - input) * 1000
        Task { @MainActor [weak self] in
          guard let self, elapsed >= 0 else { return }
          self.presentationLatencies.append(elapsed)
          if self.presentationLatencies.count > 1000 { self.presentationLatencies.removeFirst() }
        }
      }
    }
    buffer.present(drawable)
    buffer.commit()
    frames += 1
  }
  public func renderImage(size: CGSize) -> CGImage? {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .bgra8Unorm, width: Int(size.width), height: Int(size.height), mipmapped: false)
    descriptor.storageMode = .shared
    descriptor.usage = [.renderTarget, .shaderRead]
    guard let texture = device.makeTexture(descriptor: descriptor),
      let command = queue.makeCommandBuffer()
    else { return nil }
    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].texture = texture
    pass.colorAttachments[0].storeAction = .store
    encode(pass: pass, command: command, size: size)
    command.commit()
    command.waitUntilCompleted()
    var bytes = [UInt8](repeating: 0, count: Int(size.width * size.height) * 4)
    texture.getBytes(
      &bytes, bytesPerRow: Int(size.width) * 4,
      from: MTLRegionMake2D(0, 0, Int(size.width), Int(size.height)), mipmapLevel: 0)
    guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
    return CGImage(
      width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bitsPerPixel: 32,
      bytesPerRow: Int(size.width) * 4, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue).union(
        .byteOrder32Little), provider: provider, decode: nil, shouldInterpolate: false,
      intent: .defaultIntent)
  }
  private func encode(pass: MTLRenderPassDescriptor, command: MTLCommandBuffer, size: CGSize) {
    let bg = Theme.rgba(theme.background)
    guard let snapshot, size.width > 0, size.height > 0,
      let target = pass.colorAttachments[0].texture
    else {
      pass.colorAttachments[0].loadAction = .clear
      pass.colorAttachments[0].clearColor = MTLClearColor(
        red: Double(bg.x), green: Double(bg.y), blue: Double(bg.z), alpha: 1)
      command.makeRenderCommandEncoder(descriptor: pass)?.endEncoding()
      return
    }
    var fullRedraw = false
    if backing?.width != target.width || backing?.height != target.height {
      let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .bgra8Unorm, width: target.width, height: target.height, mipmapped: false)
      descriptor.storageMode = .private
      descriptor.usage = [.shaderRead, .renderTarget]
      backing = device.makeTexture(descriptor: descriptor)
      fullRedraw = true
    }
    guard let backing else { return }
    let backingPass = MTLRenderPassDescriptor()
    backingPass.colorAttachments[0].texture = backing
    backingPass.colorAttachments[0].storeAction = .store
    backingPass.colorAttachments[0].clearColor = MTLClearColor(
      red: Double(bg.x), green: Double(bg.y), blue: Double(bg.z), alpha: 1)
    if pages.count == 4 && y > atlasSize - 128 { resetAtlas() }
    let cw = rasterizer.cellWidth
    let ch = rasterizer.cellHeight
    let start = max(0, snapshot.historyCount - scrollOffset)
    let visible = Array(snapshot.lines.dropFirst(start).prefix(snapshot.rows))
    let signature =
      "\(theme.id)|\(theme.background)|\(rasterizer.pointSize)|\(size)|\(snapshot.columns)x\(snapshot.rows)|\(scrollOffset)|\(String(describing: selection))|\(String(describing: searchHit))|\(cursorStyle)"
    fullRedraw =
      fullRedraw || signature != previousSignature || previousLines.count != visible.count
    var dirty = Set<Int>()
    for row in visible.indices {
      if fullRedraw || previousLines[row] != visible[row] { dirty.insert(row) }
    }
    if previousCursor != snapshot.cursor || previousCursorVisible != cursorVisible {
      if let old = previousCursor { dirty.insert(old.row) }
      dirty.insert(snapshot.cursor.row)
    }
    if snapshot.modes.cursorVisible == false { dirty.insert(snapshot.cursor.row) }
    previousLines = visible
    previousSignature = signature
    previousCursor = snapshot.cursor
    previousCursorVisible = cursorVisible
    rowsRedrawn += dirty.count
    backingPass.colorAttachments[0].loadAction = fullRedraw ? .clear : .load
    var backgroundVertices: [Vertex] = []
    var foregroundVertices: [Int: [Vertex]] = [:]
    var overlays: [Vertex] = []
    func quad(
      _ rect: CGRect, uv: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1), color: SIMD4<Float>,
      into vertices: inout [Vertex]
    ) {
      let points = [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (0.0, 1.0), (1.0, 0.0), (1.0, 1.0)]
      for (u, v) in points {
        let px = Float((rect.minX + rect.width * CGFloat(u)) / size.width * 2 - 1)
        let py = Float(1 - (rect.minY + rect.height * CGFloat(v)) / size.height * 2)
        let tx = Float(uv.minX + uv.width * CGFloat(u))
        let ty = Float(uv.minY + uv.height * CGFloat(v))
        vertices.append(
          Vertex(position: SIMD2<Float>(px, py), uv: SIMD2<Float>(tx, ty), color: color))
      }
    }
    for row in 0..<snapshot.rows where start + row < snapshot.lines.count && dirty.contains(row) {
      let line = snapshot.lines[start + row]
      var glyphSkipUntil = 0
      for (column, cell) in line.cells.enumerated() where column < snapshot.columns {
        var fg = theme.color(cell.attributes.foreground)
        var bg = theme.color(cell.attributes.background)
        if cell.attributes.inverse { swap(&fg, &bg) }
        let position = Position(row: start + row, column: column)
        if let selection, position >= min(selection.0, selection.1),
          position <= max(selection.0, selection.1)
        {
          bg = Theme.rgba(theme.selection)
        }
        if let hit = searchHit, hit == position {
          bg = Theme.rgba(theme.cursor)
          fg = Theme.rgba(theme.background)
        }
        let rect = CGRect(
          x: 12 + CGFloat(column) * cw, y: 10 + CGFloat(row) * ch, width: cw, height: ch)
        quad(rect, color: bg, into: &backgroundVertices)
        guard cell.width > 0, column >= glyphSkipUntil else { continue }
        var cell = cell
        if ligatures && cell.width == 1 {
          for count in [3, 2] where column + count <= min(line.cells.count, snapshot.columns) {
            let run = line.cells[column..<(column + count)]
            let text = run.map(\.text).joined()
            if run.allSatisfy({ $0.width == 1 && $0.attributes == cell.attributes })
              && ["===", "!==", "==", "!=", "=>", "->", "<-", "<=", ">=", "::", ":="].contains(text)
            {
              cell = Cell(text, width: count, attributes: cell.attributes)
              glyphSkipUntil = column + count
              break
            }
          }
        }
        if cell.attributes.faint { fg *= SIMD4(0.65, 0.65, 0.65, 1) }
        if cell.text != " ", let glyph = entry(for: cell) {
          let emoji = cell.text.unicodeScalars.contains {
            $0.properties.isEmojiPresentation || $0.value == 0xFE0F
          }
          let uv = CGRect(
            x: glyph.rect.minX / CGFloat(atlasSize), y: glyph.rect.minY / CGFloat(atlasSize),
            width: glyph.rect.width / CGFloat(atlasSize),
            height: glyph.rect.height / CGFloat(atlasSize))
          var vertices = foregroundVertices[glyph.page] ?? []
          quad(
            CGRect(x: rect.minX, y: rect.minY, width: cw * CGFloat(cell.width), height: ch), uv: uv,
            color: emoji ? SIMD4(repeating: 1) : fg, into: &vertices)
          foregroundVertices[glyph.page] = vertices
        }
        if cell.attributes.underline {
          quad(
            CGRect(x: rect.minX, y: rect.maxY - 2, width: cw * CGFloat(cell.width), height: 1),
            color: fg, into: &overlays)
        }
        if cell.attributes.strike {
          quad(
            CGRect(x: rect.minX, y: rect.midY, width: cw * CGFloat(cell.width), height: 1),
            color: fg, into: &overlays)
        }
      }
    }
    if cursorVisible && snapshot.modes.cursorVisible && scrollOffset == 0
      && dirty.contains(snapshot.cursor.row)
    {
      let rect = CGRect(
        x: 12 + CGFloat(snapshot.cursor.column) * cw, y: 10 + CGFloat(snapshot.cursor.row) * ch,
        width: cw, height: ch)
      let color = Theme.rgba(theme.cursor, alpha: cursorStyle == "block" ? 0.42 : 1)
      let premultiplied = SIMD4(color.x * color.w, color.y * color.w, color.z * color.w, color.w)
      quad(
        cursorStyle == "bar"
          ? CGRect(x: rect.minX, y: rect.minY, width: 2, height: ch)
          : cursorStyle == "underline"
            ? CGRect(x: rect.minX, y: rect.maxY - 2, width: cw, height: 2) : rect,
        color: premultiplied, into: &overlays)
    }
    guard let encoder = command.makeRenderCommandEncoder(descriptor: backingPass) else { return }
    encoder.setRenderPipelineState(pipeline)
    func draw(_ vertices: [Vertex], texture: MTLTexture) {
      guard !vertices.isEmpty,
        let buffer = device.makeBuffer(
          bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride,
          options: .storageModeShared)
      else { return }
      encoder.setVertexBuffer(buffer, offset: 0, index: 0)
      encoder.setFragmentTexture(texture, index: 0)
      encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }
    draw(backgroundVertices, texture: white)
    for page in foregroundVertices.keys.sorted() {
      draw(foregroundVertices[page]!, texture: pages[page])
    }
    draw(overlays, texture: white)
    encoder.endEncoding()
    // Every drawable receives a complete frame; only persistent backing rows use load semantics.
    pass.colorAttachments[0].loadAction = .dontCare
    pass.colorAttachments[0].storeAction = .store
    if let presentEncoder = command.makeRenderCommandEncoder(descriptor: pass) {
      var vertices: [Vertex] = []
      quad(CGRect(origin: .zero, size: size), color: SIMD4(repeating: 1), into: &vertices)
      if let buffer = device.makeBuffer(
        bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride)
      {
        presentEncoder.setRenderPipelineState(pipeline)
        presentEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
        presentEncoder.setFragmentTexture(backing, index: 0)
        presentEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
      }
      presentEncoder.endEncoding()
    }
  }
}
