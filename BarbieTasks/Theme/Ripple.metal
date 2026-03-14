#include <metal_stdlib>
using namespace metal;

// Ripple distortion shader for SwiftUI .distortionEffect
// Creates a water-ripple wave emanating from a point

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

    // Wave that expands outward over time
    float wave = sin(dist * frequency - time * 12.0);

    // Decay based on distance from origin and time
    float timeDecay = max(0.0, 1.0 - time * decay);
    float distDecay = exp(-dist * 0.008);

    float displacement = wave * amplitude * timeDecay * distDecay;

    // Displace perpendicular to the wave direction
    float2 dir = dist > 0.001 ? normalize(position - origin) : float2(0, 1);
    return position + dir * displacement;
}
