//
//  Constant.h
//  mmmm
//
//  Created by wenyang on 2023/12/8.
//

#ifndef Constant_h
#define Constant_h

#include <simd/simd.h>


#define Materail_Count          8
#define Materail_Buffer_Id      0
#define Materail_id             0

#define sampler_default             0
#define shadow_sampler_default      1



#define phong_diffuse_index     0
#define phong_specular_index    1
#define phong_normal_index      2
#define phong_ambient_index     3
#define phong_emssion_index     4
#define shadow_map_index        5

#define skybox_diffuse_index     0


#define model_vertex_buffer_index                   4
#define model_vertex_tan_buffer_index               5
#define model_vertex_bitan_buffer_index             6

#define bone_object_buffer_start                    5
#define vertex_buffer_start                         3

#define model_object_buffer_index                   0
#define light_object_buffer_index                   1
#define camera_object_buffer_index                  2

#define bone_object_buffer_index                    vertex_buffer_start + bone_object_buffer_start + 1
#define bone_map_object_buffer_index                vertex_buffer_start + bone_object_buffer_start
#define vertex_boneId_buffer_size                   4

template <typename T>
union ContentBuffer {
    int count;
    T content;
};


struct CameraObject{
    simd_float4x4   projection;
    simd_float4x4   view;
    simd_float3     camera_pos;
    float           maxBias;
};

struct LightObject {
    simd_float3     light_pos;
    simd_float3     light_center;
    int             is_point_light;
    simd_float4x4   projection;
    simd_float4x4   view;
};
struct ModelObject{
    simd_float4x4   model;
    simd_float4x4   normal_model;
    float           shiness;
};




struct ModelTransform {
    simd_float4x4 modelMatrix;
    simd_float4x4 normalMatrix;
};

struct Camera{
    simd_float3 mPosition;
    
    simd_float4x4 viewMatrix;
    
    simd_float4x4 projectionMatrix;
};
typedef ContentBuffer<Camera> CameraBuffer;

enum LightType{
    LightDirection   =   1,
    LightPoint       =   2,
    LightSpot        =   3,
    LightAmbient     =   4,
    LightArea        =   5
};
struct Light{

    LightType mType;
    
    simd_float3 mPosition;

    simd_float3 mDirection;

    simd_float3 mUp;

   /** Constant light attenuation factor.
    *
    *  The intensity of the light source at a given distance 'd' from
    *  the light's position is
    *  @code
    *  Atten = 1/( att0 + att1 * d + att2 * d*d)
    *  @endcode
    *  This member corresponds to the att0 variable in the equation.
    *  Naturally undefined for directional lights.
    */
    float mAttenuationConstant;

    float mAttenuationLinear;

    float mAttenuationQuadratic;


    simd_float3 mColorDiffuse;

    simd_float3 mColorSpecular;

    simd_float3 mColorAmbient;

    float mAngleInnerCone;
    
    float mAngleOuterCone;

    simd_float2 mSize;

};
typedef ContentBuffer<Light> LightBuffer;



struct Bone{
    simd_float4x4 offsetMatrix;
    simd_float4x4 matrix;
};

struct VertexBone{
    int boneId[vertex_boneId_buffer_size];
    float weight[vertex_boneId_buffer_size];
};

typedef ContentBuffer<VertexBone> VertexBoneBuffer;

typedef ContentBuffer<Bone> BoneBuffer;

#endif /* Constant_h */
