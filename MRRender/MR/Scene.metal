//
//  Scene.metal
//  MR
//
//  Created by wenyang on 2023/12/25.
//

#include <metal_stdlib>

#include "Constant.h"
using namespace metal;

#define shiness 128

struct VertexOutScene{
    float4 position [[position]];
    float3 frag_postion;
    float2 textureCoords;
    float3 normal;
    float3 tangent;
    float3 bitangent;
    float4 color;
};

struct VertexInScene{
    float3 position         [[attribute(0)]];
    float2 textureCoords    [[attribute(1)]];
    float3 normal           [[attribute(2)]];
    float3 tangent          [[attribute(3)]];
    float3 bitangent        [[attribute(4)]];
};

struct VertexBoneInScene{
    float3 position         [[attribute(0)]];
    float2 textureCoords    [[attribute(1)]];
    float3 normal           [[attribute(2)]];
    float3 tangent          [[attribute(3)]];
    float3 bitangent        [[attribute(4)]];
};

struct VertexOutSkybox{
    float4 position [[position]];
    float3 textureCoords;
};

struct VertexInSkybox{
    float3 position         [[attribute(0)]];
    float3 textureCoords    [[attribute(1)]];
};
struct Scene{
    device const Camera         * camera [[buffer(camera_object_buffer_index)]];
    
    device const LightBuffer    * lights [[buffer(light_object_buffer_index)]];
    
    device const ModelTransform    * model [[buffer(model_object_buffer_index)]];
};



struct BoneAnimation {
    device const BoneBuffer* bone [[buffer(bone_object_buffer_index)]];
    device const VertexBoneBuffer* boneMap [[buffer(bone_map_object_buffer_index)]];
};


struct Material{
    texture2d<half> diffuse [[texture(phong_diffuse_index)]];
    
    texture2d<half> specular [[texture(phong_specular_index)]];
    
    texture2d<half> normal [[texture(phong_normal_index)]];
    
    texture2d<half> emssion  [[texture(phong_emssion_index)]];
    
    sampler sample [[sampler(sampler_default)]];
    
    half4 diffuseColor(float2 textureCoords){
        return diffuse.sample(sample, textureCoords);
    }
    half4 specularColor(float2 textureCoords){
        return specular.sample(sample, textureCoords);
    }
    half4 emssionColor(float2 textureCoords){
        return emssion.sample(sample, textureCoords);
    }
    float3 normalVector(float2 textureCoords,simd_float3x3 tbn){
        
        float3 normalVector = float3(normalize((normal.sample(sample, textureCoords) - 0.5) * 2).xyz);
        float3 normal = normalize(tbn * normalVector);
        return normal;
    }
};




simd_float3x3 createTbn(VertexOutScene vertexData){
    simd_float3x3 tbn(vertexData.tangent,vertexData.bitangent,vertexData.normal);
    return tbn;
}


float fragmentSceneSpecular(float3 camera_dir,float3 light_dir,float3 normal,float shinessv){
    float3 mid = normalize(camera_dir + light_dir);
    return  pow(max(dot(mid, normal),0.0), shinessv);
}
float lightAtteuation(const VertexOutScene inData, const Light light) {
    
    //光线距离衰退
    float distance    = length(light.mPosition - inData.frag_postion);
    float attenuation = 1.0 / (light.mAttenuationConstant + light.mAttenuationLinear * distance +
                               light.mAttenuationQuadratic * (distance * distance));
    return attenuation;
}

float spotlightEdge(float attenuation,float factor, float3 direction, const Light light) {
    //内角cos
    float cutoff = fabs(cos(light.mAngleInnerCone / 2));
    //外角cos
    float outcutoff = fabs(cos(light.mAngleOuterCone / 2));
    //边缘平滑
    float epsilon = outcutoff - cutoff;
    //光照值
    float intensity = clamp((factor - outcutoff) / epsilon, 0.0, 1.0);
    return intensity;
}


half4 fragmentSceneDiffuseDirection(VertexOutScene inData,float3 normal,Light light){
    float factor = max(dot(normalize(-light.mDirection),normal),0.0);
    return half4(half3(light.mColorDiffuse) * factor ,1);
}
//高光
half4 fragmentSceneSpecularDirection(VertexOutScene inData,float3 normal,Light light,Camera camera){
    float3 camera_dir = normalize(camera.mPosition - inData.frag_postion);
    
    float factor = fragmentSceneSpecular(camera_dir, -light.mDirection, normal,shiness);

    return half4(half3(light.mColorDiffuse) * factor ,1);
}

half4 fragmentSceneSpecularPoint(VertexOutScene inData,float3 normal,Light light,Camera camera){
    float3 direction = normalize(light.mPosition - inData.frag_postion);
    float3 camera_dir = normalize(camera.mPosition - inData.frag_postion);

    float attenuation = lightAtteuation(inData,light);
    //光照值
    float factor = fragmentSceneSpecular(camera_dir, direction, normal,shiness) * attenuation;
    return half4(half3(light.mColorDiffuse) * factor ,1);
}



half4 fragmentSceneDiffusePoint(VertexOutScene inData,float3 normal,Light light){
    float3 direction = normalize(light.mPosition - inData.frag_postion);
    //光线距离衰退

    float attenuation = lightAtteuation(inData,light);
    //光照值
    float factor = max(dot(direction,normal),0.0) * attenuation;
    return half4(half3(light.mColorDiffuse) * factor ,1);
}


half4 fragmentSceneDiffuseSpot(VertexOutScene inData,float3 normal,Light light){
    float3 direction = normalize(light.mPosition - inData.frag_postion);
    float attenuation = lightAtteuation(inData, light);
    float factor = dot(direction, -light.mDirection) * attenuation;
    float intensity = spotlightEdge(attenuation,factor, direction, light);
    
    return half4(half3(light.mColorDiffuse) * intensity ,1);
}
half4 fragmentSceneSpecularSpot(VertexOutScene inData,float3 normal,Light light,Camera camera){
    float3 direction = normalize(light.mPosition - inData.frag_postion);
    float3 camera_dir = normalize(camera.mPosition - inData.frag_postion);
    //光线距离衰退
    float attenuation = lightAtteuation(inData,light);
    //光照值
    float factor = fragmentSceneSpecular(camera_dir, -light.mDirection, normal,shiness) * attenuation;
    
    float intensity = spotlightEdge(attenuation,factor, direction, light);
    return half4(half3(light.mColorDiffuse) * intensity ,1);
}

half4 fragmentSceneAmbient(thread Scene& scene){
    for(int i = 1; i <= scene.lights->count; i++){
        if(scene.lights[i].content.mType == LightAmbient){
            return half4(half3(scene.lights[i].content.mColorAmbient),1);
        }
    }
    return half4(0,0,0,0);
}

half4 fragmentSceneDiffuse(VertexOutScene inData,
                           float3 normal,
                           Scene scene,
                           half4 diffuseColor){
    half4 diffuseLightColor = half4(0);
    for(int i = 1; i <= scene.lights->count; i++){
        if(scene.lights[i].content.mType == LightDirection){
            Light light = scene.lights[i].content;
            diffuseLightColor += fragmentSceneDiffuseDirection(inData, normal, light);
        }
        if(scene.lights[i].content.mType == LightPoint){
            Light light = scene.lights[i].content;
            diffuseLightColor += fragmentSceneDiffusePoint(inData, normal, light);
        }
        if(scene.lights[i].content.mType == LightSpot){
            Light light = scene.lights[i].content;
            diffuseLightColor += fragmentSceneDiffuseSpot(inData, normal, light);
        }
    }
    return diffuseColor * diffuseLightColor;
}
half4 fragmentSceneSpecular(VertexOutScene inData,
                           float3 normal,
                           Scene scene,
                           half4 specularColor){

    half4 specularLightColor = half4(0);
    for(int i = 1; i <= scene.lights->count; i++){
        if(scene.lights[i].content.mType == LightDirection){
            Light light = scene.lights[i].content;
            specularLightColor += fragmentSceneSpecularDirection(inData, normal, light,*scene.camera);
        }
        if(scene.lights[i].content.mType == LightPoint){
            Light light = scene.lights[i].content;
            specularLightColor += fragmentSceneSpecularPoint(inData, normal, light,*scene.camera);
        }
        if(scene.lights[i].content.mType == LightSpot){
            Light light = scene.lights[i].content;
            specularLightColor += fragmentSceneSpecularSpot(inData, normal, light,*scene.camera);
        }
    }
    return specularColor * specularLightColor;
}

fragment half4 fragmentSceneRender(VertexOutScene inData[[stage_in]],Scene scene,Material material){
    simd_float3x3 tbn = createTbn(inData);
    half4 ambient = fragmentSceneAmbient(scene);
    float3 normal = material.normalVector(inData.textureCoords, tbn);
    half4 diffuse = material.diffuseColor(inData.textureCoords);
    half4 diffuseFactor = fragmentSceneDiffuse(inData,  normal, scene, diffuse);
    half4 specular = material.specularColor(inData.textureCoords);
    half4 specularFactor = fragmentSceneSpecular(inData, normal, scene,specular);
    half4 emissive = material.emssionColor(inData.textureCoords);
    return diffuse * ambient + diffuse * diffuseFactor + specular * specularFactor + emissive;
}



vertex VertexOutScene vertexSceneRender(VertexInScene inData[[stage_in]],Scene scene){
    return VertexOutScene{
        .position = scene.camera->projectionMatrix * scene.camera->viewMatrix * scene.model->modelMatrix * float4(inData.position,1),
        .frag_postion =  (scene.model->modelMatrix * float4(inData.position,1)).xyz,
        .textureCoords = inData.textureCoords,
        .normal = normalize((scene.model->normalMatrix * float4(inData.normal,1)).xyz),
        .tangent = normalize((scene.model->normalMatrix * float4(inData.tangent,1)).xyz),
        .bitangent = normalize((scene.model->normalMatrix * float4(inData.bitangent,1)).xyz),
        .color = float4(1,1,0,1)
    };
}


vertex VertexOutScene vertexBoneSceneRender(VertexInScene inData[[stage_in]],
                                            unsigned int vertexId [[vertex_id]],
                                            BoneAnimation boneAnimation,
                                            Scene scene){
    return VertexOutScene{
        .position = scene.camera->projectionMatrix * scene.camera->viewMatrix * scene.model->modelMatrix * float4(inData.position,1),
        .frag_postion =  (scene.model->modelMatrix * float4(inData.position,1)).xyz,
        .textureCoords = inData.textureCoords,
        .normal = normalize((scene.model->normalMatrix * float4(inData.normal,1)).xyz),
        .tangent = normalize((scene.model->normalMatrix * float4(inData.tangent,1)).xyz),
        .bitangent = normalize((scene.model->normalMatrix * float4(inData.bitangent,1)).xyz),
        .color = float4(1,1,0,1)
    };
}


vertex VertexOutSkybox vertexSkyboxSceneRender(VertexInSkybox inData[[stage_in]],
                                               Scene config){
    float4x4 model(1);
    model.columns[3] = float4(config.camera->mPosition,1);
    return VertexOutSkybox{
        
        .position = config.camera->projectionMatrix * config.camera->viewMatrix * model * float4(inData.position,1.0),
        .textureCoords = inData.position
    };
}


fragment half4 fragmentSkyboxSceneRender(VertexOutSkybox vertexData[[stage_in]],
                                         sampler samp[[sampler(sampler_default)]],
                                         texturecube<half> diffuse [[texture(skybox_diffuse_index)]]){
    
    return diffuse.sample(samp, vertexData.textureCoords);
}
