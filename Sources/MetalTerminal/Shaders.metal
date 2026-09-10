#include <metal_stdlib>
using namespace metal;
struct Vertex { float2 position; float2 uv; float4 color; };
struct Raster { float4 position [[position]]; float2 uv; float4 color; };
vertex Raster terminalVertex(const device Vertex *vertices [[buffer(0)]], uint id [[vertex_id]]) {
    Raster out; out.position = float4(vertices[id].position, 0, 1); out.uv = vertices[id].uv; out.color = vertices[id].color; return out;
}
fragment float4 terminalFragment(Raster in [[stage_in]], texture2d<float> atlas [[texture(0)]]) {
    constexpr sampler sampleFilter(coord::normalized, filter::nearest);
    return atlas.sample(sampleFilter, in.uv) * in.color;
}
