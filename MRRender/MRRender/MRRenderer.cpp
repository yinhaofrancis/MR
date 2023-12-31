//
//  Renderer.cpp
//  MRender
//
//  Created by wenyang on 2023/12/17.
//

#define NS_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION

#include "MRRenderer.hpp"

#include <simd/simd.h>
#include "MRAsset.h"

using namespace MR;

static const int max_vertex_attribute = 8;

Renderer::Renderer(){
    m_textureloader = createTextureLoader(m_device);
}

Renderer::~Renderer(){
    if(this->ref_count() == 1 && m_device != nullptr){
        m_device->release();
    }
    if(this->ref_count() == 1 && m_textureloader != nullptr){
        freeObject(m_textureloader);
    }
}
const void * Renderer::textureLoader(){
    return m_textureloader;
}

Renderer* Renderer::s_shared = new Renderer();
MTL::Device& Renderer::device(){
    return *m_device;
}
MTL::Device* Renderer::devicePtr(){
    return m_device;
}
Renderer& Renderer::shared(){
    return *s_shared;
}

Buffer::Buffer(Renderer& render){
    m_render = render;
}

Buffer::~Buffer(){
    if(this->ref_count() == 1 && m_buffer != nullptr){
        m_buffer->release();
    }
}
void Buffer::assign(const void * data,size_t offset,size_t size) const{
    uint8_t * start = reinterpret_cast<uint8_t *>(m_buffer->contents());
    memcpy(start + offset, data, size);
}

void Buffer::store(size_t size,const void * data){
    if (m_buffer != nullptr){
        m_buffer->release();
    }
    m_buffer = m_render.device().newBuffer(data,size, MTL::ResourceOptionCPUCacheModeDefault);
}

MTL::Buffer * Buffer::origin() const{
    return m_buffer;
}

Texture::Texture(std::string name,Renderer& render){
    m_texture = (MTL::Texture *)loadTexture(name.c_str(), render.textureLoader());
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
Texture::Texture(simd_float4 color):Texture(2,2,MTL::PixelFormatRGBA32Float){
    simd_float4 flat[4] = {
        color,color,color,color
    };
    assign(2, 2, 4 * 4 * 2,(const void *)flat);
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
                     size_t bytePerImage) const{
    m_texture->replaceRegion(MTL::Region(0, 0,0, width, height,depth), level, slice, buffer, bytePerRow, bytePerImage);
}
void Texture::assign(size_t width,
                     size_t height,
                     size_t bytePerRow,
                     const void * buffer) const{
    assign(width, height, 1, 0, bytePerRow, buffer, 0, 0);
}
void Texture::assign(size_t width,
                     size_t height,
                     size_t bytePerRow,
                     const void *buffer,
                     size_t slice,
                     size_t bytePerImage) const{
    m_texture->replaceRegion(MTL::Region(0, 0,0, width, height,1), 0, slice, buffer, bytePerRow, bytePerImage);
}
MTL::TextureDescriptor* Texture::createDecription(){
    return MTL::TextureDescriptor::alloc()->init();;
}

MTL::Texture* Texture::origin() const{
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
MTL::SamplerState* Sampler::origin() const{
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
    auto au = NS::AutoreleasePool::alloc()->init();
    auto buff = m_queue->commandBuffer();
    callback(buff);
    buff->commit();
    buff->waitUntilCompleted();
    au->release();
    
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
                                   MTL::PixelFormatDepth32Float_Stencil8,
                                   MTL::TextureType2D,
                                   MTL::StorageModePrivate
                                   );
    }else if (m_innerDepth->m_texture->width() != texture->width() || m_innerDepth->m_texture->height() != texture->height()){
        delete m_innerDepth;
        m_innerDepth = new Texture(
                                   texture->width(),
                                   texture->height(),
                                   MTL::PixelFormatDepth32Float_Stencil8,
                                   MTL::TextureType2D,
                                   MTL::StorageModePrivate
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
    
    m_render_pass_descriptor->stencilAttachment()->setTexture(m_innerDepth->origin());
    m_render_pass_descriptor->stencilAttachment()->setClearStencil(1);
    m_render_pass_descriptor->stencilAttachment()->setLoadAction(MTL::LoadActionClear);
    m_render_pass_descriptor->stencilAttachment()->setStoreAction(MTL::StoreActionStore);
    auto encoder = buffer->renderCommandEncoder(this->m_render_pass_descriptor);
    encoder->retain();
    call(encoder);
    encoder->endEncoding();
    encoder->release();
}
void RenderPass::beginNoDepthRender(MTL::CommandBuffer* buffer,MTL::Texture* texture,RenderCallback call){
    checkInnerTexture(texture);
    m_render_pass_descriptor->colorAttachments()->object(0)->setTexture(texture);
    m_render_pass_descriptor->colorAttachments()->object(0)->setClearColor(MTL::ClearColor(0, 0, 0, 1));
    m_render_pass_descriptor->colorAttachments()->object(0)->setLoadAction(MTL::LoadActionClear);
    m_render_pass_descriptor->colorAttachments()->object(0)->setStoreAction(MTL::StoreActionDontCare);
    m_render_pass_descriptor->depthAttachment()->setTexture(nullptr);
    m_render_pass_descriptor->stencilAttachment()->setTexture(nullptr);
    auto encoder = buffer->renderCommandEncoder(this->m_render_pass_descriptor);
    encoder->retain();
    call(encoder);
    encoder->endEncoding();
    encoder->release();
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
    encoder->retain();
    call(encoder);
    encoder->endEncoding();
    encoder->release();
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
MTL::ComputePipelineState* Program::compute(const char *name){
    MTL::Function* func = m_lib->newFunction(NS::String::alloc()->init(name, NS::UTF8StringEncoding));
    NS::Error* error;
    return m_lib->device()->newComputePipelineState(func, &error);
}
Program::Program(Renderer& render){
    const char *buff = NS::Bundle::mainBundle()->bundlePath()->utf8String();
    std::string path = std::string(buff) + "/Frameworks/MR.framework/default.metallib";
    NS::Error * e;
    m_lib = render.m_device->newLibrary(NS::String::alloc()->init(path.c_str(), NS::UTF8StringEncoding), &e);
    if(e != nullptr){
        throw (MR::Error){e->domain()->utf8String(),0};
    }
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





Mesh::Mesh(Renderer& render)
:m_postion(render)
,m_normal(render)
,m_textureCoords(render)
,m_tangents(render)
,m_bitangents(render)
,m_color(render)
,m_index(render){
    m_vertexDescriptor = MTL::VertexDescriptor::alloc()->init();
}
Mesh::~Mesh(){
    if (ref_count() == 1 && m_vertexDescriptor != nullptr) {
        m_vertexDescriptor->release();
    }
}

int& Mesh::uvComponentCount(){
    return m_uvComponent;
}

size_t& Mesh::vertexCount(){
    return m_vertex_count;
}
MTL::IndexType& Mesh::indexType(){
    return m_indexType;
}
bool Mesh::hasBuffer(VertexComponent vertexComponent) const{
    switch (vertexComponent) {
            
        case Position:
            return m_postion.origin()->length() > 0;
        case TextureCoords:
            return m_textureCoords.origin()->length() > 0;
        case Normal:
            return m_normal.origin()->length() > 0;
        case Tangent:
            return m_tangents.origin()->length() > 0;
        case Bitangent:
            return m_bitangents.origin()->length() > 0;
        case Color:
            return m_color.origin()->length() > 0;
        case Index:
            return m_index.origin()->length() > 0;
        case BoneMap:
            return m_bone_map.origin()->length() > 0;
        case Bone:
            return m_bone.origin()->length() > 0;
    }
}
const Buffer& Mesh::operator[](VertexComponent vertexComponent) const{
    switch (vertexComponent) {
            
        case Position:
            return m_postion;
        case TextureCoords:
            return m_textureCoords;
        case Normal:
            return m_normal;
        case Tangent:
            return m_tangents;
        case Bitangent:
            return m_bitangents;
        case Color:
            return m_color;
        case Index:
            return m_index;
        case BoneMap:
            return m_bone_map;
        case Bone:
            return m_bone;
    }
}
MTL::PrimitiveType& Mesh::primitiveMode(){
    return m_pm;
}

void Mesh::buffer(size_t size,const void *buffer,Mesh::VertexComponent vertexComponent){
    switch (vertexComponent) {
        
        case Position:
            m_postion.store(size, buffer);
            break;
        case TextureCoords:
            m_textureCoords.store(size, buffer);
            break;
        case Normal:
            m_normal.store(size, buffer);
            break;
        case Tangent:
            m_tangents.store(size, buffer);
            break;
        case Bitangent:
            m_bitangents.store(size, buffer);
            break;
        case Color:
            m_color.store(size, buffer);
            break;
        case Index:
            m_index.store(size, buffer);
            break;
        case BoneMap:
            m_bone_map.store(size, buffer);
            break;
        case Bone:
            m_bone.store(size, buffer);
            break;
    }
}
void Mesh::buildVertexDescriptor(){
    for (int i = 0; i < max_vertex_attribute; i++) {
        layoutVertexDescriptor((Mesh::VertexComponent)i);
    }
}
MTL::VertexDescriptor* Mesh::vertexDescriptor() const{
    return m_vertexDescriptor;
}
void Mesh::draw(MTL::RenderCommandEncoder* encoder) const{

    for (int i = 0; i < max_vertex_attribute; i++) {
        Mesh::VertexComponent idex = (Mesh::VertexComponent)i;
        if(hasBuffer(idex)){
            encoder->setVertexBuffer((*this)[idex].origin(), 0, i + vertex_buffer_start);
        }else{
            encoder->setVertexBuffer(nullptr, 0, i + vertex_buffer_start);
        }
    }
    
    if (hasBuffer(VertexComponent::Index)) {
        encoder->drawIndexedPrimitives(this->m_pm, m_vertex_count, m_indexType, m_index.origin(), 0);
    }else{
        encoder->drawPrimitives(this->m_pm, 0, this->m_vertex_count,1,0);
    }
}
void Mesh::layoutVertexDescriptor(Mesh::VertexComponent vertexComponent){
    if (!hasBuffer(vertexComponent)){
        return;
    }
    int index = vertex_buffer_start + vertexComponent;
    switch (vertexComponent) {
        case Position:
            m_vertexDescriptor->attributes()->object(vertexComponent)->setFormat(MTL::VertexFormat::VertexFormatFloat3);
            m_vertexDescriptor->attributes()->object(vertexComponent)->setOffset(0);
            m_vertexDescriptor->attributes()->object(vertexComponent)->setBufferIndex(index);
            m_vertexDescriptor->layouts()->object(index)->setStride(sizeof(float) * 3);
            m_vertexDescriptor->layouts()->object(index)->setStepRate(1);
            m_vertexDescriptor->layouts()->object(index)->setStepFunction(MTL::VertexStepFunctionPerVertex);
            break;
        case TextureCoords:
            if (uvComponentCount() == 3){
                m_vertexDescriptor->attributes()->object(vertexComponent)->setFormat(MTL::VertexFormat::VertexFormatFloat3);
                m_vertexDescriptor->layouts()->object(index)->setStride(sizeof(float) * 3);
            }else{
                m_vertexDescriptor->attributes()->object(vertexComponent)->setFormat(MTL::VertexFormat::VertexFormatFloat2);
                m_vertexDescriptor->layouts()->object(index)->setStride(sizeof(float) * 2);
            }
            m_vertexDescriptor->attributes()->object(vertexComponent)->setOffset(0);
            m_vertexDescriptor->attributes()->object(vertexComponent)->setBufferIndex(index);
            
            m_vertexDescriptor->layouts()->object(index)->setStepRate(1);
            m_vertexDescriptor->layouts()->object(index)->setStepFunction(MTL::VertexStepFunctionPerVertex);
            break;
        case Normal:
            m_vertexDescriptor->attributes()->object(vertexComponent)->setFormat(MTL::VertexFormat::VertexFormatFloat3);
            m_vertexDescriptor->attributes()->object(vertexComponent)->setOffset(0);
            m_vertexDescriptor->attributes()->object(vertexComponent)->setBufferIndex(index);
            m_vertexDescriptor->layouts()->object(index)->setStride(sizeof(float) * 3);
            m_vertexDescriptor->layouts()->object(index)->setStepRate(1);
            m_vertexDescriptor->layouts()->object(index)->setStepFunction(MTL::VertexStepFunctionPerVertex);
            break;
        case Tangent:
            m_vertexDescriptor->attributes()->object(vertexComponent)->setFormat(MTL::VertexFormat::VertexFormatFloat3);
            m_vertexDescriptor->attributes()->object(vertexComponent)->setOffset(0);
            m_vertexDescriptor->attributes()->object(vertexComponent)->setBufferIndex(index);
            m_vertexDescriptor->layouts()->object(index)->setStride(sizeof(float) * 3);
            m_vertexDescriptor->layouts()->object(index)->setStepRate(1);
            m_vertexDescriptor->layouts()->object(index)->setStepFunction(MTL::VertexStepFunctionPerVertex);
            break;
        case Bitangent:
            m_vertexDescriptor->attributes()->object(vertexComponent)->setFormat(MTL::VertexFormat::VertexFormatFloat3);
            m_vertexDescriptor->attributes()->object(vertexComponent)->setOffset(0);
            m_vertexDescriptor->attributes()->object(vertexComponent)->setBufferIndex(index);
            m_vertexDescriptor->layouts()->object(index)->setStride(sizeof(float) * 3);
            m_vertexDescriptor->layouts()->object(index)->setStepRate(1);
            m_vertexDescriptor->layouts()->object(index)->setStepFunction(MTL::VertexStepFunctionPerVertex);
            break;
        case Color:
            m_vertexDescriptor->attributes()->object(vertexComponent)->setFormat(MTL::VertexFormat::VertexFormatFloat4);
            m_vertexDescriptor->attributes()->object(vertexComponent)->setOffset(0);
            m_vertexDescriptor->attributes()->object(vertexComponent)->setBufferIndex(index);
            m_vertexDescriptor->layouts()->object(index)->setStride(sizeof(float) * 4);
            m_vertexDescriptor->layouts()->object(index)->setStepRate(1);
            m_vertexDescriptor->layouts()->object(index)->setStepFunction(MTL::VertexStepFunctionPerVertex);
            break;
        default:
            break;
    }
}

Materal::Materal(Texture diffuse,Texture specular,Texture normal,Texture emission)
:m_diffuse(diffuse),
m_specular(specular),
m_emission(emission),
m_sampler(Sampler::linear()),
m_normal(normal){
    
}
void Materal::load(MTL::RenderCommandEncoder *encoder){
    encoder->setFragmentTexture(m_diffuse.origin(), phong_diffuse_index);
    encoder->setFragmentTexture(m_specular.origin(), phong_specular_index);
    encoder->setFragmentTexture(m_normal.origin(), phong_normal_index);
    encoder->setFragmentTexture(m_emission.origin(), phong_emssion_index);
    encoder->setFragmentSamplerState(m_sampler.origin(), sampler_default);
}

Materal Materal::defaultMateral(){
    Texture d (simd_make_float4(0.5, 0.5, 0.5, 1));
    Texture s (simd_make_float4(1, 1, 1, 1));
    Texture n (simd_make_float4(0.5, 0.5, 1, 1));
    Texture e (simd_make_float4(0.0, 0.0, 0, 0));
    return Materal(d, s, n,e);
}
Texture Materal::defaultSkyboxMateral(){
    Texture tex(2, 2, MTL::PixelFormatRGBA8Unorm_sRGB,MTL::TextureTypeCube);
    uint8_t buff[] = {
        255,0,0,255,
        0,255,0,255,
        0,0,255,255,
        255,0,255,255
    };
    tex.assign(2, 2, 8,buff , 0, 16);
    tex.assign(2, 2, 8,buff , 1, 16);
    tex.assign(2, 2, 8,buff , 2, 16);
    tex.assign(2, 2, 8,buff , 3, 16);
    tex.assign(2, 2, 8,buff , 4, 16);
    tex.assign(2, 2, 8,buff , 5, 16);
    return tex;
}


SceneObject::SceneObject(){
    
}
void SceneObject::setCamera(Camera &camera){
    m_camera = camera;
}
void SceneObject::add(Light light){
    LightBuffer b;
    b.content = light;
    lights.push_back(b);
}
void SceneObject::setModel(ModelTransform& model){
    m_model = model;
}
void SceneObject::load(MTL::RenderCommandEncoder *encoder) const{
    encoder->setVertexBytes(&m_model, sizeof(m_model), model_object_buffer_index);
    encoder->setFragmentBytes(&m_model, sizeof(m_model), model_object_buffer_index);
    
    encoder->setVertexBytes(&m_camera, sizeof(m_camera), camera_object_buffer_index);
    encoder->setFragmentBytes(&m_camera, sizeof(m_camera), camera_object_buffer_index);
    LightBuffer * buffer = new LightBuffer[lights.size() + 1];
    for (int i = 1; i <= lights.size(); i++) {
        buffer[i] = lights[i - 1];
    }
    buffer[0].count = (int)lights.size();
    encoder->setVertexBytes(buffer, sizeof(LightBuffer) * (lights.size() + 1), light_object_buffer_index);
    encoder->setFragmentBytes(buffer, sizeof(LightBuffer) * (lights.size() + 1), light_object_buffer_index);
    delete [] buffer;
    
}
