//
//  shader.metal
//  MR
//
//  Created by wenyang on 2023/12/8.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "Constant.h"

using namespace metal;



struct VertexOutMesh{
    float4 position [[position]];
    float3 frag_position;
    float3 normal;
    float3 tangent;
    float3 bitangent;
};

struct VertexInMesh{
    float3 position [[attribute(0)]];
    float2 uv[[attribute(1)]];
    float3 normal[[attribute(2)]];
    float3 tangent[[attribute(3)]];
    float3 bitangent[[attribute(4)]];
};




struct VertexOutPlain{
    float4 position [[position]];
    float3 frag_postion;
    float2 uv;
    float3 normal;
    float3 tangent;
    float3 bitangent;
    float3 color;
};
struct VertexInPlain{
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
    float3 tangent[[attribute(3)]];
    float3 bitangent[[attribute(4)]];
};

struct VertexScreenDisplay{
    float4 position [[position]];
    float2 uv;
};

struct VertexOutSkybox{
    float4 position[[position]];
    float3 uv;
};

struct ModelHeapMaterial{
    array<texture2d<half>,Materail_Count> textures [[id(Materail_id)]];
};

struct ModelMaterial{
    texture2d<half>     m_diffuse           [[texture(phong_diffuse_index)]];
    texture2d<half>     m_specular          [[texture(phong_specular_index)]];
    texture2d<half>     m_normal            [[texture(phong_normal_index)]];
    texturecube<half>   m_ambient           [[texture(phong_ambient_index)]];
    sampler             m_sampler           [[sampler(0)]];
};

struct SceneModelConfiguration{
    device const CameraObject* camera_object [[buffer(camera_object_buffer_index)]];
    device const LightObject* light_object [[buffer(light_object_buffer_index)]];
    device const ModelObject* object_object [[buffer(model_object_buffer_index)]];
};


vertex VertexOutMesh vertexMeshRender(VertexInMesh inData[[stage_in]],
                                      device const CameraObject* camera_object [[buffer(camera_object_buffer_index)]],
                                      device const ModelObject* object_object [[buffer(model_object_buffer_index)]]
                                      ){
    return VertexOutMesh{
        .position = float4(inData.position,1.0),
        .frag_position = inData.position,
        .normal = inData.normal,
        .tangent = inData.tangent,
        .bitangent = inData.bitangent
    };
}
fragment half4 fragmentMeshRender(
                            VertexOutMesh vertexData[[stage_in]],
                            ModelMaterial materail
                            ){
    return half4(1,0,0,1);
}


vertex VertexOutPlain vertexPlainRender(VertexInPlain inData[[stage_in]],
                                        SceneModelConfiguration config){
    auto frag =  config.object_object->model * float4(inData.position,1.0);
    return VertexOutPlain{
        .uv = inData.uv,
        .frag_postion = frag.xyz,
        .color = inData.position,
        .position = config.camera_object->projection * config.camera_object->view * frag,
        .normal = normalize((config.object_object->normal_model * float4(inData.normal,1)).xyz),
        .tangent = normalize((config.object_object->normal_model * float4(inData.tangent,1)).xyz),
        .bitangent = normalize((config.object_object->normal_model * float4(inData.bitangent,1)).xyz),
    };
}


fragment half4 fragmentPlainRender(VertexOutPlain vertexData[[stage_in]],ModelMaterial m,SceneModelConfiguration config){
    
    half4 color = m.m_diffuse.sample(m.m_sampler,vertexData.uv);
    
    half4 spec = m.m_specular.sample(m.m_sampler,vertexData.uv);
    
    simd_float3x3 tbn(cross(vertexData.normal,vertexData.bitangent),vertexData.bitangent,vertexData.normal);

    float3 norcolor = normalize(float3(m.m_normal.sample(m.m_sampler,vertexData.uv).xyz) * 2.0 - 1.0);
    
    simd_float3 normal = normalize(tbn * norcolor);
//    simd_float3 normal = vertexData.normal;
    
    simd_float3 light_dir = normalize(config.light_object->light_pos - config.light_object->light_center);
    float diffuse_factor = max(dot(light_dir,normal) + 0.01,0.01);
    
    simd_float3 cam_dir = normalize(config.camera_object->camera_pos - vertexData.frag_postion);
    simd_float3 halfVector = normalize(cam_dir + light_dir);
    float specOrigin = dot(halfVector, normal);
    float specv = pow(max(specOrigin, 0.0), config.object_object->shiness);
    spec *= specv;
//    return ;
    return color * diffuse_factor + spec;
}



vertex VertexOutSkybox vertexSkyboxRender(VertexInPlain inData[[stage_in]],
                                          SceneModelConfiguration config){
    float4x4 model(1);
    model.columns[3] = float4(config.camera_object->camera_pos,1);
    return VertexOutSkybox{
        
        .position = config.camera_object->projection * config.camera_object->view * model * float4(inData.position,1.0),
        .uv = inData.position
    };
}


fragment half4 fragmentSkyboxRender(VertexOutSkybox vertexData[[stage_in]],ModelMaterial m){
    
    return m.m_ambient.sample(m.m_sampler,vertexData.uv);
}




constant float2 screenPlant[] = {
    float2(-1, -1),
    float2(-1,  1),
    float2( 1,  1),
    float2(-1, -1),
    float2( 1,  1),
    float2( 1, -1)
};

vertex VertexScreenDisplay VertexScreenDisplayRender(unsigned short vertexId [[vertex_id]]){
    VertexScreenDisplay vsd;
    float2 position = screenPlant[vertexId];
    vsd.position = float4(position,0,1);
    vsd.position.y *= -1;
    vsd.uv = position * 0.5 + 0.5;
    return vsd;
}

fragment half4 FragmentScreenDisplayRender(VertexScreenDisplay in [[stage_in]],
                                            texture2d<half> texture,sampler sam){
    
    const half3 color = texture.sample(sam, in.uv).xyz;
    
    return half4(color, 1.0f);
}
