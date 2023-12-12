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




#define phong_diffuse_index     0
#define phong_specular_index    1
#define phong_normal_index      2
#define phong_ambient_index     3



#define model_object_buffer_index                   0
#define light_object_buffer_index                   1
#define camera_object_buffer_index                  2
#define model_vertex_buffer_index                   3
#define model_vertex_tan_buffer_index               4
#define model_vertex_bitan_buffer_index             5



struct CameraObject{
    simd_float4x4   projection;
    simd_float4x4   view;
    simd_float3     camera_pos;
};

struct LightObject {
    simd_float3     light_pos;
    simd_float3     light_center;
    int             is_point_light;
};
struct ModelObject{
    simd_float4x4   model;
    simd_float4x4   normal_model;
    float           shiness;
};
#endif /* Constant_h */
