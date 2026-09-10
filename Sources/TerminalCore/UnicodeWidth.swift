import Foundation

/// Unicode 17 extended grapheme boundaries, including GB9c, GB11 and regional indicators.
enum UnicodeWidth {
  static func joins(_ previous: String, _ next: String) -> Bool {
    if previous.utf8.count == 1 && next.utf8.count == 1 { return previous == "\r" && next == "\n" }
    let scalars = previous.unicodeScalars.map(\.value)
    guard let a = scalars.last, let b = next.unicodeScalars.first?.value else { return false }
    let pa = UnicodeData.property(a, in: UnicodeData.gcb)
    let pb = UnicodeData.property(b, in: UnicodeData.gcb)
    if pa == 1 && pb == 2 { return true }
    if [1, 2, 3].contains(pa) || [1, 2, 3].contains(pb) { return false }
    if pa == 9 && [9, 10, 12, 13].contains(pb) { return true }
    if [10, 12].contains(pa) && [10, 11].contains(pb) { return true }
    if [11, 13].contains(pa) && pb == 11 { return true }
    if [4, 5, 8].contains(pb) || pa == 7 { return true }
    if UnicodeData.property(b, in: UnicodeData.incb) == 1 {
      var linker = false
      for scalar in scalars.reversed() {
        let p = UnicodeData.property(scalar, in: UnicodeData.incb)
        if p == 3 {
          linker = true
        } else if p == 2 {
          continue
        } else if p == 1 && linker {
          return true
        } else {
          break
        }
      }
    }
    if pa == 5 && UnicodeData.property(b, in: UnicodeData.pictographic) == 1 {
      for scalar in scalars.dropLast().reversed() {
        if UnicodeData.property(scalar, in: UnicodeData.gcb) == 4 { continue }
        return UnicodeData.property(scalar, in: UnicodeData.pictographic) == 1
      }
    }
    if pa == 6 && pb == 6 {
      return scalars.reversed().prefix { UnicodeData.property($0, in: UnicodeData.gcb) == 6 }.count
        % 2 == 1
    }
    return false
  }
  static func width(_ text: String) -> Int {
    if text.utf8.count == 1 { return 1 }
    let values = text.unicodeScalars.map(\.value)
    if values.contains(0xFE0F)
      && values.contains(where: {
        UnicodeData.property($0, in: UnicodeData.pictographic) == 1 || $0 == 0x23 || $0 == 0x2A
          || (0x30...0x39).contains($0)
      })
    {
      return 2
    }
    if values.contains(0x20E3) { return 2 }
    guard let base = values.first else { return 1 }
    if UnicodeData.property(base, in: UnicodeData.wide) == 1 { return 2 }
    if !values.contains(0xFE0E)
      && UnicodeData.property(base, in: UnicodeData.emojiPresentation) == 1
    {
      return 2
    }
    return 1
  }
}
