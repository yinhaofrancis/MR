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


void sphereMesh(simd_float3 size,simd_uint2 segment,bool hasTangent,void *vmesh){
    MDLMesh* mesh = [[MDLMesh alloc] initSphereWithExtent:size segments:segment inwardNormals:false geometryType:MDLGeometryTypeTriangles allocator:nil];
    if(hasTangent){
        [mesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate tangentAttributeNamed:MDLVertexAttributeTangent bitangentAttributeNamed:MDLVertexAttributeBitangent];
        [mesh makeVerticesUniqueAndReturnError:nil];
    }
    MR::Mesh* mmesh = (MR::Mesh*)vmesh;
    MTLVertexDescriptor *descriptor = (__bridge MTLVertexDescriptor *)mmesh->vertexDescriptor();
    positionNorTexDescription(descriptor, vertex_buffer_start, 0);
    if(hasTangent){
        float3Description(descriptor, vertex_buffer_start + 1, 3);
        float3Description(descriptor, vertex_buffer_start + 2, 4);
    }
    MDLMeshBufferData* data0 = mesh.vertexBuffers[0];
    mmesh->buffer(data0.length, data0.data.bytes, MR::Mesh::Position);
    if (hasTangent){
        MDLMeshBufferData* data1 = mesh.vertexBuffers[1];
        mmesh->buffer(data1.length, data1.data.bytes, MR::Mesh::Tangent);
        MDLMeshBufferData* data2 = mesh.vertexBuffers[2];
        mmesh->buffer(data2.length, data2.data.bytes, MR::Mesh::Bitangent);
    }
    NSMutableData * idexbuff = [[NSMutableData alloc] init];
    unsigned int count = 0;
    for (int i = 0; i < mesh.submeshes.count; i++) {
        count += mesh.submeshes[i].indexCount;
        [idexbuff appendData:((MDLMeshBufferData*)mesh.submeshes[i].indexBuffer).data];
    }
    
    mmesh->vertexCount() = count;
    mmesh->buffer(idexbuff.length, idexbuff.bytes, MR::Mesh::Index);
    mmesh->indexType() = MTL::IndexTypeUInt16;
    
}


void sphereSkybox(float size,void *vmesh){
    sphereMesh(simd_make_float3(size, size, size), simd_make_uint2(20, 20),false,vmesh);
}
