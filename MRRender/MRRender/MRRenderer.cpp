//
//  Renderer.cpp
//  MRender
//
//  Created by wenyang on 2023/12/17.
//

#include "MRRenderer.hpp"


using namespace MR;

Renderer::Renderer(){}

Renderer::~Renderer(){
    if(this->ref_count() == 1 && m_device != nullptr){
        m_device->release();
    }
}

Renderer* Renderer::s_shared = new Renderer();
MTL::Device& Renderer::device(){
    return *m_device;
}
Renderer& Renderer::shared(){
    return *s_shared;
}

Buffer::Buffer(size_t size,const void *buffer,Renderer& render){
    if(size != 0){
        if(buffer == nullptr){
            m_buffer = render.m_device->newBuffer(size, MTL::ResourceOptionCPUCacheModeDefault);
        }else{
            m_buffer = render.m_device->newBuffer(buffer, size, MTL::ResourceOptionCPUCacheModeDefault);
        }
    }
}

Buffer::~Buffer(){
    if(this->ref_count() == 1 && m_buffer != nullptr){
        m_buffer->release();
    }
}
void Buffer::assign(const void * data,size_t offset,size_t size){
    uint8_t * start = reinterpret_cast<uint8_t *>(m_buffer->contents());
    memcpy(start + offset, data, size);
}
void Buffer::store(size_t size,const void * data){
    if(m_buffer->length() != size){
        auto device = m_buffer->device();
        m_buffer->release();
        device->newBuffer(data, size, MTL::ResourceOptionCPUCacheModeDefault);
    }else{
        memcpy(m_buffer->contents(), data, size);
    }
}

MTL::Buffer * Buffer::origin(){
    return m_buffer;
}


Texture::Texture(MTL::TextureDescriptor* desciptor, Renderer& render){
    m_texture = render.m_device->newTexture(desciptor);
}
Texture::Texture(size_t width,
                 size_t height,
                 MTL::PixelFormat pixel,
                 MTL::TextureType type,
                 MTL::StorageMode storage,
                 MTL::TextureUsage usage,
                 MTL::TextureSwizzleChannels* swizzleChannel,
                 Renderer& render){
    MTL::TextureDescriptor* desciptor = MTL::TextureDescriptor::alloc()->init();
    desciptor->setWidth(width);
    desciptor->setHeight(height);
    desciptor->setPixelFormat(pixel);
    desciptor->setUsage(usage);
    desciptor->setTextureType(type);
    desciptor->setStorageMode(storage);
    if(swizzleChannel != nullptr){
        desciptor->setSwizzle(*swizzleChannel);
    }
    m_texture = render.m_device->newTexture(desciptor);
    desciptor->release();
}
Texture::~Texture(){
    if(ref_count() == 1 && m_texture != nullptr){
        m_texture->release();
    }
}
void Texture::assign(size_t width,
                     size_t height,
                     size_t depth,
                     size_t level,
                     size_t bytePerRow,
                     const void *buffer,
                     size_t slice,
                     size_t bytePerImage){
    m_texture->replaceRegion(MTL::Region(0, 0,0, width, height,depth), level, slice, buffer, bytePerRow, bytePerImage);
}
void Texture::assign(size_t width,
                     size_t height,
                     size_t bytePerRow,
                     const void * buffer){
    assign(width, height, 1, 0, bytePerRow, buffer, 0, 0);
}
void Texture::assign(size_t width,
                     size_t height,
                     size_t bytePerRow,
                     const void *buffer,
                     size_t slice,
                     size_t bytePerImage){
    m_texture->replaceRegion(MTL::Region(0, 0,0, width, height,1), 0, slice, buffer, bytePerRow, bytePerImage);
}
MTL::TextureDescriptor* Texture::createDecription(){
    return MTL::TextureDescriptor::alloc()->init();;
}

MTL::Texture* Texture::origin(){
    return m_texture;
}


Sampler::Sampler(MTL::SamplerDescriptor *desc, Renderer& render){
    m_sampler = render.m_device->newSamplerState(desc);
}
Sampler::Sampler(MTL::SamplerMinMagFilter filter,
                 MTL::SamplerAddressMode addressMode,
                 Renderer& render){
    MTL::SamplerDescriptor* desc = MTL::SamplerDescriptor::alloc()->init();
    desc->setMagFilter(filter);
    desc->setMinFilter(filter);
    desc->setRAddressMode(addressMode);
    desc->setSAddressMode(addressMode);
    desc->setTAddressMode(addressMode);
    m_sampler = render.m_device->newSamplerState(desc);
    desc->release();
}


Sampler* Sampler::m_linear = new Sampler(MTL::SamplerMinMagFilterLinear, MTL::SamplerAddressModeRepeat);

Sampler* Sampler::m_nearest = new Sampler(MTL::SamplerMinMagFilterNearest, MTL::SamplerAddressModeRepeat);

Sampler& Sampler::linear(){
    return *m_linear;
}
Sampler& Sampler::nearest(){
    return *m_nearest;
}
MTL::SamplerState* Sampler::origin(){
    return m_sampler;
}
Sampler::~Sampler(){
    if(ref_count() == 1 && m_sampler != nullptr){
        m_sampler->release();
    }
}
Queue::Queue(Renderer& render):m_render(render){
    m_queue = render.m_device->newCommandQueue();
}
Queue* Queue::s_shared = new Queue(Renderer::shared());

Queue& Queue::shared(){
    return *s_shared;
}
Queue::~Queue(){
    if(ref_count() == 1 && m_queue != nullptr){
        m_queue->release();
    }
}
void Queue::beginBuffer(BufferCallBack callback){
    auto buff = m_queue->commandBuffer();
    callback(buff);
    buff->commit();
    buff->waitUntilCompleted();
}
void Queue::beginCompute(ComputeCallBack callback){
    beginBuffer([callback](MTL::CommandBuffer* buffer){
        auto encoder = buffer->computeCommandEncoder();
        callback(encoder);
        encoder->endEncoding();
    });
}



MTL::RenderPassDescriptor& RenderPass::renderPassDescriptor(){
    return *m_render_pass_descriptor;
}
void RenderPass::checkInnerTexture(MTL::Texture *texture) {
    if(m_innerDepth == nullptr){
        m_innerDepth = new Texture(
                                   texture->width(),
                                   texture->height(),
                                   MTL::PixelFormatDepth32Float_Stencil8
                                   );
    }else if (m_innerDepth->m_texture->width() != texture->width() || m_innerDepth->m_texture->height() != texture->height()){
        delete m_innerDepth;
        m_innerDepth = new Texture(
                                   texture->width(),
                                   texture->height(),
                                   MTL::PixelFormatDepth32Float_Stencil8
                                   );
    }
    
    if(m_innerStencial == nullptr){
        m_innerStencial = new Texture(
                                      texture->width(),
                                      texture->height(),
                                      MTL::PixelFormatDepth32Float_Stencil8
                                      );
    }else if (m_innerStencial->m_texture->width() != texture->width() || m_innerStencial->m_texture->height() != texture->height()){
        delete m_innerStencial;
        m_innerStencial = new Texture(
                                      texture->width(),
                                      texture->height(),
                                      MTL::PixelFormatDepth32Float_Stencil8
                                      );
    }
}

void RenderPass::beginRender(MTL::CommandBuffer* buffer,MTL::Texture* texture,RenderCallback call){
    checkInnerTexture(texture);
    m_render_pass_descriptor->colorAttachments()->object(0)->setTexture(texture);
    m_render_pass_descriptor->colorAttachments()->object(0)->setClearColor(MTL::ClearColor(0, 0, 0, 1));
    m_render_pass_descriptor->colorAttachments()->object(0)->setLoadAction(MTL::LoadActionClear);
    m_render_pass_descriptor->colorAttachments()->object(0)->setStoreAction(MTL::StoreActionStore);
    
    m_render_pass_descriptor->depthAttachment()->setTexture(m_innerDepth->origin());
    m_render_pass_descriptor->depthAttachment()->setClearDepth(1);
    m_render_pass_descriptor->depthAttachment()->setLoadAction(MTL::LoadActionClear);
    m_render_pass_descriptor->depthAttachment()->setStoreAction(MTL::StoreActionStore);
    
    m_render_pass_descriptor->stencilAttachment()->setTexture(m_innerStencial->origin());
    m_render_pass_descriptor->stencilAttachment()->setClearStencil(1);
    m_render_pass_descriptor->stencilAttachment()->setLoadAction(MTL::LoadActionClear);
    m_render_pass_descriptor->stencilAttachment()->setStoreAction(MTL::StoreActionStore);
    auto encoder = buffer->renderCommandEncoder(this->m_render_pass_descriptor);
    call(encoder);
    encoder->endEncoding();
}
void RenderPass::beginNoDepthRender(MTL::CommandBuffer* buffer,MTL::Texture* texture,RenderCallback call){
    checkInnerTexture(texture);
    m_render_pass_descriptor->colorAttachments()->object(0)->setTexture(texture);
    m_render_pass_descriptor->colorAttachments()->object(0)->setClearColor(MTL::ClearColor(0, 0, 0, 1));
    m_render_pass_descriptor->colorAttachments()->object(0)->setLoadAction(MTL::LoadActionClear);
    m_render_pass_descriptor->colorAttachments()->object(0)->setStoreAction(MTL::StoreActionStore);
    m_render_pass_descriptor->depthAttachment()->setTexture(nullptr);
    m_render_pass_descriptor->stencilAttachment()->setTexture(nullptr);
    auto encoder = buffer->renderCommandEncoder(this->m_render_pass_descriptor);
    call(encoder);
    encoder->endEncoding();
}

void RenderPass::beginNoDepthRender(MTL::CommandBuffer* buffer,CA::MetalDrawable * drawable,RenderCallback call){
    
    auto currentColorTexture = drawable->texture();
    beginNoDepthRender(buffer,currentColorTexture, call);
    buffer->presentDrawable(drawable);
}
void RenderPass::beginRender(MTL::CommandBuffer* buffer,CA::MetalDrawable * drawable,RenderCallback call){
    auto currentColorTexture = drawable->texture();
    beginRender(buffer,currentColorTexture, call);
    buffer->presentDrawable(drawable);
}
void RenderPass::beginDepth(MTL::CommandBuffer* buffer,MTL::Texture* texture,RenderCallback call){
    m_render_pass_descriptor->colorAttachments()->object(0)->setTexture(nullptr);
    m_render_pass_descriptor->depthAttachment()->setTexture(m_innerDepth->origin());
    m_render_pass_descriptor->depthAttachment()->setClearDepth(1);
    m_render_pass_descriptor->depthAttachment()->setLoadAction(MTL::LoadActionClear);
    m_render_pass_descriptor->depthAttachment()->setStoreAction(MTL::StoreActionStore);
    m_render_pass_descriptor->stencilAttachment()->setTexture(nullptr);
    auto encoder = buffer->renderCommandEncoder(this->m_render_pass_descriptor);
    call(encoder);
    encoder->endEncoding();
}
RenderPass::RenderPass(){
    m_render_pass_descriptor = MTL::RenderPassDescriptor::alloc()->init();
}
RenderPass::~RenderPass(){
    if(ref_count() == 1 && m_render_pass_descriptor != nullptr){
        m_render_pass_descriptor->release();
    }
}

Program* Program::s_shared = new Program();

Program&  Program::shared(){
    return *s_shared;
}
Program::Program(Renderer& render){
    m_lib = render.m_device->newDefaultLibrary();
}
Program::Program(const char* path,Renderer& render){
    NS::Error * e;
    m_lib = render.m_device->newLibrary(NS::String::alloc()->init(path, NS::UTF8StringEncoding), &e);
    if(e != nullptr){
       
        throw (MR::Error){e->domain()->utf8String(),0};
    }
}
Program::~Program(){
    if (ref_count() == 1 && m_lib != nullptr) {
        m_lib->release();
    }
}
MTL::Function* Program::shader(const char *name){
    return m_lib->newFunction(NS::String::alloc()->init(name, NS::UTF8StringEncoding));
}


const uint64_t s_time = 1000000 / 60;
void vsyncCall(Vsync::SyncCallBack call){
    bool a = true;
    uint64_t lasttimestamp = 0;
    while(a){
        auto now = std::chrono::system_clock::now();
        auto timestamp = std::chrono::duration_cast<std::chrono::microseconds>(now.time_since_epoch()).count();
        lasttimestamp = timestamp + s_time;
        a = call();
        now = std::chrono::system_clock::now();
        timestamp = std::chrono::duration_cast<std::chrono::microseconds>(now.time_since_epoch()).count();
        if(lasttimestamp > timestamp){
            auto delay  = lasttimestamp - timestamp;
            std::this_thread::sleep_for(std::chrono::microseconds(delay));
        }else{
            auto delay = s_time - ((timestamp - lasttimestamp) % s_time);
            std::this_thread::sleep_for(std::chrono::microseconds(delay));
        }
        
    }
    
}


Vsync::Vsync(SyncCallBack call){
    std::thread k(vsyncCall,call);
    k.detach();
}
Vsync::~Vsync(){
    
}
