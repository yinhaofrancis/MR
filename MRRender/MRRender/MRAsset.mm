//
//  MRAsset.m
//  MRRender
//
//  Created by wenyang on 2023/12/31.
//

#import "MRAsset.h"
#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>
#include <MR/Constant.h>
#include "MRRenderer.hpp"

void positionNorTexDescription(MTLVertexDescriptor* desc,int bufferIndex,int attributeIndex){
    desc.layouts[bufferIndex].stride = 32;
    desc.layouts[bufferIndex].stepRate = 1;
    desc.layouts[bufferIndex].stepFunction = MTLVertexStepFunctionPerVertex;
    // position
    desc.attributes[attributeIndex].offset = 0;
    desc.attributes[attributeIndex].format = MTLVertexFormatFloat3;
    desc.attributes[attributeIndex].bufferIndex = bufferIndex;
    // normal
    desc.attributes[attributeIndex + 1].offset = 12;
    desc.attributes[attributeIndex + 1].format = MTLVertexFormatFloat3;
    desc.attributes[attributeIndex + 1].bufferIndex = bufferIndex;
    // uv
    desc.attributes[attributeIndex + 2].offset = 24;
    desc.attributes[attributeIndex + 2].format = MTLVertexFormatFloat2;
    desc.attributes[attributeIndex + 2].bufferIndex = bufferIndex;
    
}
void float3Description(MTLVertexDescriptor* desc,int bufferIndex,int attributeIndex){
    desc.layouts[bufferIndex].stride = 12;
    desc.layouts[bufferIndex].stepRate = 1;
    desc.layouts[bufferIndex].stepFunction = MTLVertexStepFunctionPerVertex;
    desc.attributes[attributeIndex].offset = 0;
    desc.attributes[attributeIndex].format = MTLVertexFormatFloat3;
    desc.attributes[attributeIndex].bufferIndex = bufferIndex;
}

id<MTLDevice> deviceTransform(const void *renderer){
    MR::Renderer *r = (MR::Renderer *)renderer;
    return (__bridge id<MTLDevice>)r->devicePtr();
}
void * createTextureLoader(const void *renderer){
    id<MTLDevice> device = deviceTransform(renderer);
    return (void *)CFBridgingRetain([[MTKTextureLoader alloc] initWithDevice:device]);
}

void freeObject(const void *textureloader){
    CFBridgingRelease(textureloader);
}

void * loadTexture(const char * name,const void * textureloader){
    MTKTextureLoader *loader = (__bridge MTKTextureLoader *)(textureloader);
    NSDictionary* option = @{
        MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModeShared),
        MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead)
    };
    auto texture = [loader newTextureWithName:[NSString stringWithUTF8String:name] scaleFactor:1 bundle:nil options:option error:nil];
    return(__bridge_retained MTL::Texture*)texture ;
}


void sphereMesh(simd_float3 size,simd_uint2 segment,void *vmesh,const void *renderer){
    id<MTLDevice> device = deviceTransform(renderer);
    MTKMeshBufferAllocator* a = [[MTKMeshBufferAllocator alloc] initWithDevice:device];
    MDLMesh* mesh = [[MDLMesh alloc] initSphereWithExtent:size segments:segment inwardNormals:false geometryType:MDLGeometryTypeTriangles allocator:a];
    [mesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate tangentAttributeNamed:MDLVertexAttributeTangent bitangentAttributeNamed:MDLVertexAttributeBitangent];
    [mesh makeVerticesUniqueAndReturnError:nil];
    MR::Mesh* mmesh = (MR::Mesh*)vmesh;
    MTLVertexDescriptor *descriptor = (__bridge MTLVertexDescriptor *)mmesh->vertexDescriptor();
    positionNorTexDescription(descriptor, vertex_buffer_start, 0);
    float3Description(descriptor, vertex_buffer_start + 1, 3);
    float3Description(descriptor, vertex_buffer_start + 2, 4);
    MTKMesh *mkmesh = [[MTKMesh alloc] initWithMesh:mesh device:device error:nil];
    MR::Buffer buffer1;
    buffer1.store((MTL::Buffer*)CFBridgingRetain(mkmesh.vertexBuffers[0].buffer));
    mmesh->buffer(buffer1, MR::Mesh::Position);
    
    MR::Buffer buffer2;
    buffer2.store((MTL::Buffer*)CFBridgingRetain(mkmesh.vertexBuffers[1].buffer));
    mmesh->buffer(buffer2, MR::Mesh::Tangent);
    
    MR::Buffer buffer3;
    buffer3.store((MTL::Buffer*)CFBridgingRetain(mkmesh.vertexBuffers[2].buffer));
    mmesh->buffer(buffer3, MR::Mesh::Bitangent);    
}


void sphereSkybox(float size,void *vmesh,const void *renderer){
    sphereMesh(simd_make_float3(size, size, size), simd_make_uint2(20, 20),vmesh, renderer);
}
