//
//  Renderer.hpp
//  MRender
//
//  Created by wenyang on 2023/12/17.
//

#ifndef Renderer_hpp
#define Renderer_hpp

#include <iostream>
#include <glm/glm.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <glm/ext.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <simd/simd.h>
#include <assimp/Importer.hpp>
#include <assimp/scene.h>
#include <assimp/postprocess.h>
#define NS_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>
#include "MRObject.hpp"
#include <MR/Constant.h>

namespace MR {

static MTL::PixelFormat colorTexturePixel = MTL::PixelFormatRGBA8Unorm_sRGB;
static MTL::PixelFormat depthTexturePixel = MTL::PixelFormatDepth32Float;
static MTL::PixelFormat depthStencialTexturePixel = MTL::PixelFormatDepth32Float_Stencil8;

struct Error{
    const char* message;
    int code;
};

class Renderer:virtual Object{
public:
    Renderer();
    ~Renderer();
    
    static Renderer& shared();
    
    friend class Buffer;
    friend class Texture;
    friend class Sampler;
    friend class Queue;
    friend class Program;
    MTL::Device& device();
private:
    MTL::Device* m_device = MTL::CreateSystemDefaultDevice();
    static Renderer *s_shared;
    static std::mutex m_lock_shared;
};

class Buffer:virtual Object {
public:
    Buffer(Renderer& render = Renderer::shared());
    ~Buffer();
    void assign(const void * data,size_t offset,size_t size) const;
    void store(size_t size,const void * data);
    MTL::Buffer * origin() const;
private:
    MTL::Buffer *m_buffer = nullptr;
    Renderer m_render;
};

class Texture:virtual Object{
public:
    Texture(MTL::TextureDescriptor* desciptor,
            Renderer& render = Renderer::shared());
    
    Texture(size_t width,
            size_t height,
            MTL::PixelFormat pixel,
            MTL::TextureType type = MTL::TextureType2D,
            MTL::StorageMode storage = MTL::StorageModeShared,
            MTL::TextureUsage usage  = MTL::TextureUsageShaderRead | MTL::TextureUsageRenderTarget,
            MTL::TextureSwizzleChannels* swizzleChannel = nullptr,
            Renderer& render = Renderer::shared());
    
    Texture(simd_float4 color);
    ~Texture();
    static MTL::TextureDescriptor* createDecription();
    MTL::Texture* origin() const;
    void assign(size_t width,
                size_t height,
                size_t depth,
                size_t level,
                size_t bytePerRow,
                const void * buffer,
                size_t slice,
                size_t perImageSize) const;
    
    void assign(size_t width,
                size_t height,
                size_t bytePerRow,
                const void * buffer,
                size_t slice,
                size_t bytePerImage) const;
    
    void assign(size_t width,
                size_t height,
                size_t bytePerRow,
                const void * buffer) const;
    friend class RenderPass;
private:
    MTL::Texture *m_texture = nullptr;
    MTL::TextureDescriptor* m_desciptor = nullptr;
};

class Sampler:virtual Object{
public:
    Sampler(MTL::SamplerDescriptor *,Renderer& render = Renderer::shared());
    Sampler(MTL::SamplerMinMagFilter ,MTL::SamplerAddressMode ,Renderer& render = Renderer::shared());
    ~Sampler();
    MTL::SamplerState* origin();
    static Sampler& linear();
    static Sampler& nearest();
private:
    MTL::SamplerState* m_sampler = nullptr;
    
    static Sampler* m_linear;
    static Sampler* m_nearest;
    
};

class Queue:virtual Object{
public:
    typedef std::function<void(MTL::CommandBuffer*)> BufferCallBack;
    typedef std::function<void(MTL::ComputeCommandEncoder*)> ComputeCallBack;
    Queue(Renderer& render = Renderer::shared());
    ~Queue();
    void beginBuffer(BufferCallBack callback);
    void beginCompute(ComputeCallBack callback);
    static Queue& shared();
private:
    MTL::CommandQueue* m_queue = nullptr;
    Renderer m_render;
    static Queue* s_shared;
};

class Program:virtual Object{
public:
    Program(Renderer& render = Renderer::shared());
    Program(const char* path,Renderer& render = Renderer::shared());
    ~Program();
    MTL::Function* shader(const char *name);
    MTL::ComputePipelineState* compute(const char *name);
    static Program& shared();
private:
    static Program *s_shared;
    MTL::Library* m_lib = nullptr;
};

class RenderPass:virtual Object{
    
public:
    typedef std::function<void(MTL::RenderCommandEncoder*)> RenderCallback;
    MTL::RenderPassDescriptor& renderPassDescriptor();
    
    
    void beginRender(MTL::CommandBuffer* buffer,MTL::Texture* texture,RenderCallback call);
    void beginRender(MTL::CommandBuffer* buffer,CA::MetalDrawable * drawable,RenderCallback call);
    void beginDepth(MTL::CommandBuffer* buffer,MTL::Texture* texture,RenderCallback call);
    void beginNoDepthRender(MTL::CommandBuffer* buffer,MTL::Texture* texture,RenderCallback call);
    void beginNoDepthRender(MTL::CommandBuffer* buffer,CA::MetalDrawable * drawable,RenderCallback call);
    RenderPass();
    ~RenderPass();
private:
    
    void checkInnerTexture(MTL::Texture *texture);
    MTL::RenderPassDescriptor* m_render_pass_descriptor = nullptr;
    Texture* m_innerDepth;
};

class Mesh:virtual Object{
public:
    
    enum VertexComponent{
        Position,
        TextureCoords,
        Normal,
        Tangent,
        Bitangent,
        Color,
        Index,
    };
    
    Mesh(Renderer& render = Renderer::shared());
    ~Mesh();
    
    int& uvComponentCount();
    
    size_t& vertexCount();
    
    bool hasBuffer(VertexComponent vertexComponent);
    
    Buffer& operator[](VertexComponent vertexComponent);
    
    MTL::PrimitiveType& primitiveMode();
    
    MTL::IndexType& indexType();
    
    void buffer(size_t size,const void *buffer,Mesh::VertexComponent vertexComponent);
    
    MTL::VertexDescriptor* vertexDescriptor();
    void draw(MTL::RenderCommandEncoder *encoder);
    
private:
    void layoutVertexDescriptor(Mesh::VertexComponent vertexComponent);
    
private:
    Buffer m_postion;
    Buffer m_normal;
    Buffer m_tangents;
    Buffer m_bitangents;
    Buffer m_textureCoords;
    Buffer m_color;
    Buffer m_index;
    int m_uvComponent           = 2;
    size_t m_vertex_count       = 0;
    MTL::IndexType m_indexType    = MTL::IndexTypeUInt16;
    MTL::PrimitiveType m_pm     = MTL::PrimitiveTypeTriangle;
    MTL::VertexDescriptor *m_vertexDescriptor;
};

struct Materal{

    Materal(Texture diffuse,Texture specular,Texture normal);
    void load(MTL::RenderCommandEncoder *encoder);
    static Materal defaultMateral();

    Texture m_diffuse;
    Texture m_specular;
    Texture m_normal;
    Sampler m_sampler;
    
};



class SceneObject{
public:
    SceneObject();
    void load(MTL::RenderCommandEncoder *encoder) const;
    void add(Light light);
    void setCamera(Camera& camera);
    void setModel(ModelTransform& model);
private:
    Camera m_camera;
    ModelTransform m_model;
    std::vector<LightBuffer> lights;
};


};



#endif /* Renderer_hpp */
