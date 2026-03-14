#include <metal_stdlib>
using namespace metal;

// Ripple distortion shader — iMessage-style water ripple
// Displaces pixels in a wave pattern emanating from an origin point

[[ stitchable ]] float2 ripple(
    float2 position,
    float4 bounds,
    float time,
    float2 origin,
    float amplitude,
    float frequency,
    float decay
) {
    float dist = distance(position, origin);

    // Expanding wave
    float wave = sin(dist * frequency - time * 14.0);

    // Distance-based falloff so it spreads naturally
    float distFalloff = exp(-dist * 0.004);

    // Time-based decay
    float timeFalloff = max(0.0, 1.0 - time * decay * 0.5);

    float displacement = wave * amplitude * distFalloff * timeFalloff;

    // Displace along the radial direction from origin
    float2 dir = dist > 0.001 ? normalize(position - origin) : float2(0, 1);
    return position + dir * displacement;
}
