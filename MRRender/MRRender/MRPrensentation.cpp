//
//  MRPrensentation.cpp
//  MRRender
//
//  Created by wenyang on 2023/12/18.
//

#include "MRPrensentation.hpp"
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
