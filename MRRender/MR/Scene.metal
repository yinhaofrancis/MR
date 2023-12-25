//
//  Scene.metal
//  MR
//
//  Created by wenyang on 2023/12/25.
//

#include <metal_stdlib>

#include "Constant.h"
using namespace metal;


struct VertexOutScene{
    float4 position [[position]];
    float4 color;
};
struct VertexInScene{
    float3 position         [[attribute(0)]];
    float3 normal           [[attribute(1)]];
    float2 textureCoords    [[attribute(2)]];
    float3 tangent          [[attribute(3)]];
    float3 bitangent        [[attribute(4)]];
};
struct Scene{
    device const CameraBuffer * cameras [[buffer(camera_object_buffer_index)]];
    device const LightBuffer  * lights [[buffer(light_object_buffer_index)]];
    device const ModelBuffer  * model [[buffer(model_object_buffer_index)]];
};


vertex VertexOutScene vertexSceneRender(VertexInScene inData[[stage_in]],Scene scene){
    float4x4 m(scene.model->modelMatrix);
    return VertexOutScene{
        .position = float4(inData.position,1),
        .color = float4(1,1,0,1)
    };
}

fragment half4 fragmentSceneRender(VertexOutScene inData[[stage_in]],Scene scene){
    return half4(inData.color);
}


