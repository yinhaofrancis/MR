//
//  Export.c
//  MRRender
//
//  Created by wenyang on 2023/12/17.
//

#include "Export.h"

#include "MRRenderer.hpp"
#include "MRPrensentation.hpp"
#include <Metal/Metal.hpp>


static CA::MetalLayer* m_layer;

static MR::RenderPass* m_render_pass = new MR::RenderPass();

static MR::RenderScreen * renderScreen = new MR::RenderScreen();


void closeRender(){
    CFRelease(m_layer);
    m_layer = nullptr;
   
}
void beginRender(void * layer){
    if(m_layer != nullptr){
        closeRender();
    }
    m_layer = (CA::MetalLayer*)layer;
    
    MR::Vsync([](){
        return true;
    });
}

void renderBitmap(void * drawable,int width,int height,int bytePerRow,const void * buffer){
    CA::MetalDrawable* current = (CA::MetalDrawable*)drawable;

    MR::Texture texture(width,height,MTL::PixelFormatRGBA8Unorm_sRGB,MTL::TextureType2D,MTL::StorageModeShared);
    texture.assign(width, height, bytePerRow, buffer);
    MR::Queue::shared().beginBuffer([current, &texture](auto buffer){
        m_render_pass->beginNoDepthRender(buffer, current, [&texture](auto encoder){
            renderScreen->render(texture, MR::Sampler::nearest(), encoder);
        });
    });
    
    
    
}
