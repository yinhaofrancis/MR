//
//  MRPrensentation.cpp
//  MRRender
//
//  Created by wenyang on 2023/12/18.
//

#include "MRPrensentation.hpp"
#include "MRAsset.h"

using namespace MR;
RenderScreen::RenderScreen(Renderer& render ,Program& program){
    auto desc = MTL::RenderPipelineDescriptor::alloc()->init();
    desc->colorAttachments()->object(0)->setPixelFormat(MR::colorTexturePixel);
    auto v = program.shader("FragmentScreenDisplayRender");
    auto f = program.shader("VertexScreenDisplayRender");
    desc->setFragmentFunction(v);
    desc->setVertexFunction(f);
    NS::Error * e;
    m_state = render.device().newRenderPipelineState(desc, &e);
    desc->release();
    v->release();
    f->release();
    if(e != nullptr){
        throw (MR::Error) {e->domain()->utf8String(),1};
    }
    
}

void RenderScreen::render(Texture& texture,Sampler& sampler,MTL::RenderCommandEncoder * encoder) const {
    encoder->setRenderPipelineState(m_state);
    encoder->setFragmentTexture(texture.origin(), 0);
    encoder->setFragmentSamplerState(sampler.origin(), 0);
    encoder->drawPrimitives(MTL::PrimitiveTypeTriangle, 0, 6, 1, 0);
}
RenderScreen::~RenderScreen(){
    if(m_state != nullptr && ref_count() == 1){
        m_state->release();
    }
}

void RenderScene::loadState(std::string vertex,
                            std::string fragment,
                            MTL::RenderPipelineState ** state,
                            Program &program,
                            Renderer &render,
                            MTL::VertexDescriptor *vertexDescriptor) {
    auto desc = MTL::RenderPipelineDescriptor::alloc()->init();
    desc->colorAttachments()->object(0)->setPixelFormat(MR::colorTexturePixel);
    desc->setDepthAttachmentPixelFormat(MR::depthStencialTexturePixel);
    desc->setStencilAttachmentPixelFormat(MR::depthStencialTexturePixel);
    desc->setVertexDescriptor(vertexDescriptor);
    desc->colorAttachments()->object(0)->setBlendingEnabled(true);
    desc->colorAttachments()->object(0)->setSourceAlphaBlendFactor(MTL::BlendFactorSourceAlpha);
    desc->colorAttachments()->object(0)->setDestinationAlphaBlendFactor(MTL::BlendFactorOneMinusBlendAlpha);
    auto f = program.shader(fragment.c_str());
    auto v = program.shader(vertex.c_str());
    desc->setFragmentFunction(f);
    desc->setVertexFunction(v);
    
    NS::Error * e;
    *state = render.device().newRenderPipelineState(desc, &e);
    if(e != nullptr){
        throw (MR::Error) {e->domain()->utf8String(),1};
    }
    desc->release();
    v->release();
    f->release();
}

RenderScene::RenderScene(MTL::VertexDescriptor* vertexDescriptor,Renderer& render,Program& program){
    loadState("vertexSceneRender","fragmentSceneRender",&m_state,program, render, vertexDescriptor);
    loadState("vertexBoneSceneRender","fragmentSceneRender",&m_bone_state,program, render, vertexDescriptor);
    MTL::DepthStencilDescriptor* dep = MTL::DepthStencilDescriptor::alloc()->init();
    dep->setDepthWriteEnabled(true);
    dep->setDepthCompareFunction(MTL::CompareFunctionLess);
    m_depth = render.device().newDepthStencilState(dep);
}
RenderScene::~RenderScene(){
    if(m_state != nullptr && ref_count() == 1){
        m_state->release();
    }
    if(m_bone_state != nullptr && ref_count() == 1){
        m_bone_state->release();
    }
    if(m_depth != nullptr && ref_count() == 1){
        m_depth->release();
    }
}
void RenderScene::render(MR::Mesh& mesh,MTL::RenderCommandEncoder * encoder) const{
    if (mesh.hasBuffer(Mesh::BoneMap)) {
        encoder->setRenderPipelineState(m_bone_state);
    }else{
        encoder->setRenderPipelineState(m_state);
    }
    encoder->setDepthStencilState(m_depth);
    
    mesh.draw(encoder);
}

RenderSkyboxScene::RenderSkyboxScene(Renderer& render,Program& program){
    sphereSkybox(20,(void *)&mesh,&render);
    loadState("vertexSkyboxSceneRender","fragmentSkyboxSceneRender",&m_state,program, render,mesh.vertexDescriptor());
    MTL::DepthStencilDescriptor* dep = MTL::DepthStencilDescriptor::alloc()->init();
    dep->setDepthWriteEnabled(true);
    dep->setDepthCompareFunction(MTL::CompareFunctionLess);
    m_depth = render.device().newDepthStencilState(dep);
    
}
RenderSkyboxScene::~RenderSkyboxScene(){
    if(m_state != nullptr && ref_count() == 1){
        m_state->release();
    }
    if(m_depth != nullptr && ref_count() == 1){
        m_depth->release();
    }
}
void RenderSkyboxScene::render(MTL::Texture *texture,MTL::RenderCommandEncoder * encoder) const{
    
    encoder->setRenderPipelineState(m_state);
    encoder->setDepthStencilState(m_depth);
    encoder->setFragmentTexture(texture, skybox_diffuse_index);
    mesh.draw(encoder);
}
void RenderSkyboxScene::loadState(std::string vertex,
                                  std::string fragment,
                                  MTL::RenderPipelineState ** state,
                                  Program &program,
                                  Renderer &render,
                                  MTL::VertexDescriptor *vertexDescriptor){
    auto desc = MTL::RenderPipelineDescriptor::alloc()->init();
    desc->colorAttachments()->object(0)->setPixelFormat(MR::colorTexturePixel);
    desc->setDepthAttachmentPixelFormat(MR::depthStencialTexturePixel);
    desc->setStencilAttachmentPixelFormat(MR::depthStencialTexturePixel);
    desc->setVertexDescriptor(vertexDescriptor);
    desc->colorAttachments()->object(0)->setBlendingEnabled(true);
    desc->colorAttachments()->object(0)->setSourceAlphaBlendFactor(MTL::BlendFactorSourceAlpha);
    desc->colorAttachments()->object(0)->setDestinationAlphaBlendFactor(MTL::BlendFactorOneMinusBlendAlpha);
    auto f = program.shader(fragment.c_str());
    auto v = program.shader(vertex.c_str());
    desc->setFragmentFunction(f);
    desc->setVertexFunction(v);
    
    NS::Error * e;
    *state = render.device().newRenderPipelineState(desc, &e);
    if(e != nullptr){
        throw (MR::Error) {e->domain()->utf8String(),1};
    }
    desc->release();
    v->release();
    f->release();
}



void MR::lookAt(Camera& camera,glm::vec3 eye,glm::vec3 center,glm::vec3 up){

    camera.mPosition = simd_make_float3(eye.x, eye.y, eye.z);
    
    memcpy(&camera.viewMatrix, glm::value_ptr(glm::lookAt(eye, center, up)), sizeof(camera.viewMatrix));
}
void MR::perspective(Camera& camera,float fovy,float aspect,float near,float far){
    glm::mat4 mat = glm::perspective(fovy, aspect, near, far);
    memcpy(&camera.projectionMatrix, glm::value_ptr(mat), sizeof(camera.projectionMatrix));
}

void MR::modelTransform(ModelTransform& transform,glm::mat4 matrix){
    memcpy(&transform.modelMatrix, glm::value_ptr(matrix), sizeof(transform.modelMatrix));
    memcpy(&transform.normalMatrix, glm::value_ptr(glm::inverseTranspose(matrix)), sizeof(transform.normalMatrix));
}
