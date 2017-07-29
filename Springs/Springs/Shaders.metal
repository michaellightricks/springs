//
//  Shaders.metal
//  Springs
//
//  Created by Michael Kupchick on 3/6/16.
//  Copyright © 2016 Michael Kupchick. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "SharedStructures.h"

using namespace metal;

// Variables in constant address space
constant float3 light_position = float3(0.0, 1.0, -1.0);
constant float4 ambient_color  = float4(0.18, 0.24, 0.8, 1.0);
constant float4 diffuse_color  = float4(0.4, 0.4, 1.0, 1.0);

typedef struct
{
    float4 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
  //float2 texCoords [[attribute(2)]];
} vertex_t;

typedef struct {
    float4 position [[position]];
    half4  color;
} ColorInOut;

// Vertex shader function
vertex ColorInOut lighting_vertex(vertex_t vertex_array [[stage_in]],
                                  constant uniforms_t& uniforms [[ buffer(1) ]])
{
    ColorInOut out;
    
    out.position = uniforms.modelview_projection_matrix * vertex_array.position;
    
    float4 eye_normal = normalize(uniforms.normal_matrix * float4(vertex_array.normal, 0.0));
    float n_dot_l = dot(eye_normal.rgb, normalize(light_position));
    n_dot_l = fmax(0.0, n_dot_l);
    
    out.color = half4(ambient_color + diffuse_color * n_dot_l);
    return out;
}

// Fragment shader function
fragment half4 lighting_fragment(ColorInOut in [[stage_in]])
{
    return in.color;
}

kernel void kernel_function(device float4 *vertex_array [[ buffer(0) ]],
                            uint gid [[ thread_position_in_grid ]])
{
  if (gid == 0) {
    vertex_array[gid] = - 0.5;
  }
}
