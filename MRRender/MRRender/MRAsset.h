//
//  MRAsset.h
//  MRRender
//
//  Created by wenyang on 2023/12/31.
//

#ifndef MRAsset_H
#define MRAsset_H

#include <simd/simd.h>

void * createTextureLoader(const void *renderer);

void   freeObject(const void *textureloader);

void * loadTexture(const char * name,const void * textureloader);

void sphereSkybox(float size,void *vmesh);

void sphereMesh(simd_float3 size,simd_uint2 segment,bool hasTangent,void *vmesh);

#endif
