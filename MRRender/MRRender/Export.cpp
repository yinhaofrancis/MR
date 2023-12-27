//
//  Export.c
//  MRRender
//
//  Created by wenyang on 2023/12/17.
//

#include "Export.h"

#include "MRRenderer.hpp"
#include "MRPrensentation.hpp"
#include "MRModel.hpp"
#include <Metal/Metal.hpp>
#include <MR/Constant.h>

#include "MRVsync.h"


static CA::MetalLayer* m_layer;

static MR::RenderPass* m_render_pass = new MR::RenderPass();

static MR::RenderScreen * renderScreen = new MR::RenderScreen();

static MR::Mesh mesh;

static MR::RenderScene* state;

static MR::Materal m = MR::Materal::defaultMateral();

static MR::Program pro = MR::Program::shared();

void beginMesh(const char * url){

    std::string s = url;
    MR::Scene sc(s);
    m = sc.phone(0, 0);
    mesh = sc.mesh(0);
    MTL::VertexDescriptor* vt = mesh.vertexDescriptor();
    state = new MR::RenderScene(vt);
   
}
static float v = 0;

static void rederCall(CA::MetalDrawable *current) {
    Camera cam;
    cam.mPosition = simd_make_float3(3, 3, 3);
    
    memcpy(&cam.viewMatrix, glm::value_ptr(glm::lookAt(glm::vec3(3), glm::vec3(0,2,0), glm::vec3(0,1,0))), sizeof(cam.viewMatrix));
    
    float asp = 1;
    if(current->texture()->height() > 0 && current->texture()->width() > 0){
        asp = (float)current->texture()->width() / (float)current->texture()->height();
    }
    glm::mat4 mat = glm::perspective(45.0f, asp, 1.0f, 1500.0f);
    memcpy(&cam.projectionMatrix, glm::value_ptr(mat), sizeof(cam.projectionMatrix));
    
    Light aLight;
    aLight.mType = LightAmbient;
    aLight.mColorAmbient = simd_make_float3(0.1, 0.1, 0.1);
    
    Light dLight;
    dLight.mType = LightDirection;
    dLight.mDirection = simd_make_float3(cos(v), -1,sin(v));
    v += 0.01;
    dLight.mColorDiffuse = simd_make_float3(1, 1, 1);
    dLight.mColorSpecular = simd_make_float3(1, 1, 1);
    
    ModelBuffer mb;
    
    
    memcpy(&mb.modelMatrix, glm::value_ptr(glm::mat4(1)), sizeof(mb.modelMatrix));
    memcpy(&mb.normalMatrix, glm::value_ptr(glm::mat4(1)), sizeof(mb.normalMatrix));
    MR::SceneObject so;
    so.setModel(mb);
    so.setCamera(cam);
    so.add(aLight);
    so.add(dLight);
    
    
    
    MR::Queue::shared().beginBuffer([current,mb, so](auto buffer){
        m_render_pass->beginRender(buffer, current, [&so](auto encoder){
            m.load(encoder);
            so.load(encoder);
            state->render(mesh, encoder);
        });
    });
}

void drawMesh(void *o){
    rederCall((CA::MetalDrawable *)o);
}
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
void test(){
    Camera* m = new Camera();
    memset(m, 0, sizeof(Camera));
    MR::Buffer b;
    b.store(10 * sizeof(Camera), m);
    auto compute = pro.compute("track");
    MR::Queue::shared().beginCompute([b, compute](MTL::ComputeCommandEncoder* encoder){
        encoder->setComputePipelineState(compute);
        encoder->setBuffer(b.origin(), 0, 0);
        MTL::Size s(9, 1, 1);
        MTL::Size m(1, 1, 1);
        encoder->dispatchThreadgroups(s, m);
    });
}
