//
//  Renderer.swift
//  TFRender
//
//  Created by wenyang on 2023/12/11.
//


import Metal
import MetalKit
import simd
import Foundation

public struct Configuration{
    public static let ColorPixelFormat:MTLPixelFormat           = .rgba8Unorm_srgb
    public static let DepthpixelFormat:MTLPixelFormat           = .depth32Float
    public static let DepthStencilpixelFormat:MTLPixelFormat    = .depth32Float_stencil8
    
    public static let bundle:Bundle = Bundle(identifier: "com.yh.TFRender")!
}

public enum TRError:Error{
    case createObjectFail(String)
}

public class Renderer{
    
    public static let shared:Renderer = try! Renderer()
    
    public init() throws{
        guard let device = MTLCreateSystemDefaultDevice() else { throw TRError.createObjectFail("device create fail") }
        self.device = device
    }
    public init(device:MTLDevice){
        self.device = device
    }
    public var device:MTLDevice
    
    public private(set) lazy var defaultDepthState:MTLDepthStencilState = {
        let desc = MTLDepthStencilDescriptor()
        desc.depthCompareFunction = .less
        desc.isDepthWriteEnabled = true
        return self.device.makeDepthStencilState(descriptor: desc)!
    }()
    
    public private(set) lazy var skyboxDepthState:MTLDepthStencilState = {
        let desc = MTLDepthStencilDescriptor()
        desc.depthCompareFunction = .always
        desc.isDepthWriteEnabled = false
        return self.device.makeDepthStencilState(descriptor: desc)!
    }()
}

extension Renderer {
    public struct Buffer{
        public var buffer:MTLBuffer
        public init(size:Int,renderer:Renderer = Renderer.shared) throws{
            guard let buff = renderer.device.makeBuffer(length: size) else { throw TRError.createObjectFail("buffer create fail") }
            self.buffer = buff
        }
        public func copy(buffer:UnsafeRawPointer,size:Int){
            self.buffer.contents().copyMemory(from: buffer, byteCount: size)
        }
        public func store<T>(obj:T,offset:Int = 0,type:T.Type){
            self.buffer.contents().storeBytes(of: obj, toByteOffset: offset, as: type)
        }
    }
    
    public struct Shader{
        
        public static let shared:Shader = try! Shader(render: Renderer.shared)
        
        public let lib:MTLLibrary
        
        public var render:Renderer{
            return Renderer(device: lib.device)
        }
        
        public init(url:URL,render:Renderer = Renderer.shared) throws {
            self.lib = try render.device.makeLibrary(URL: url)
        }
        
        public init(bundle:Bundle = Configuration.bundle,render:Renderer = Renderer.shared) throws {
            self.lib = try render.device.makeDefaultLibrary(bundle: bundle)
        }
        public func createFunction(functionName:String)throws ->MTLFunction{
            guard let function = lib.makeFunction(name: functionName) else { throw TRError.createObjectFail("create function fail") }
            return function
        }
    }
    public struct Sampler{
        public var samplerState:MTLSamplerState
        public var render:Renderer{
            return Renderer(device: samplerState.device)
        }
        public init(samplerState: MTLSamplerState) {
            self.samplerState = samplerState
        }
        public init(descriptor:MTLSamplerDescriptor,render:Renderer = Renderer.shared) throws {
            guard let sampler = render.device.makeSamplerState(descriptor: descriptor) else { throw TRError.createObjectFail("sampler create fail")}
            self.init(samplerState: sampler)
        }
        public static let defaultSampler:Sampler = {
            let desc = MTLSamplerDescriptor();
            desc.magFilter = .linear
            desc.minFilter = .linear
            desc.mipFilter = .linear
            desc.rAddressMode = .clampToEdge
            desc.sAddressMode = . clampToEdge
            desc.tAddressMode = .clampToEdge
            return try! Sampler(descriptor: desc)
        }()
        public static let defaultNesrestSampler:Sampler = {
            let desc = MTLSamplerDescriptor();
            desc.magFilter = .nearest
            desc.minFilter = .nearest
            desc.mipFilter = .nearest
            desc.rAddressMode = .repeat
            desc.sAddressMode = .repeat
            desc.tAddressMode = .repeat
            return try! Sampler(descriptor: desc)
        }()
    }
    
    public struct Texture{
        public var texture:MTLTexture
        public var render:Renderer{
            return Renderer(device: texture.device)
        }
        public var sampler:Sampler
        public init(texture: MTLTexture,samplerState:MTLSamplerState = Renderer.Sampler.defaultSampler.samplerState) {
            self.texture = texture
            sampler = Sampler(samplerState: samplerState)
        }
        
        public init(textureDescriptor:MTLTextureDescriptor,sampler:Sampler,render:Renderer = .shared) throws {
            guard let texture = render.device.makeTexture(descriptor: textureDescriptor) else { throw TRError.createObjectFail("texture create fail")}
            self.init(texture: texture,samplerState:sampler.samplerState)
        }
        
        public init(width:Int,
                    height:Int,
                    pixel:MTLPixelFormat,
                    type:MTLTextureType = .type2D,
                    storeMode:MTLStorageMode = .shared,
                    colorSwizzle:MTLTextureSwizzle? = nil,
                    usage:MTLTextureUsage = [.shaderRead,],
                    render:Renderer = .shared) throws{
            let desc = MTLTextureDescriptor()
            desc.width = width
            desc.height = height
            desc.storageMode = storeMode
            if let colorSwizzle{
                desc.swizzle = MTLTextureSwizzleChannels(red: colorSwizzle, green: colorSwizzle, blue: colorSwizzle, alpha: colorSwizzle)
            }
            desc.pixelFormat = pixel
            desc.usage = usage
            desc.textureType = type
            try self.init(textureDescriptor:desc,sampler:Sampler.defaultSampler, render: render)
        }
        
        public func assign(width:Int,
                           height:Int,
                           bytesPerRow:Int,
                           withBytes: UnsafeRawPointer){
            
            self.assign(region: MTLRegionMake2D(0, 0, width, height),
                        bytes: withBytes,
                        bytesPerRow: bytesPerRow)
        }
        public func assign(region:MTLRegion,
                           level:Int = 0,
                           bytes:UnsafeRawPointer,
                           bytesPerRow:Int){
            self.texture.replace(region: region, mipmapLevel: level, withBytes: bytes, bytesPerRow: bytesPerRow)
            
        }
        public func assign(region:MTLRegion,
                           level:Int = 0,
                           slice:Int,
                           bytes:UnsafeRawPointer,
                           bytesPerRow:Int,
                           bytePerImage:Int){
            self.texture.replace(region: region, mipmapLevel: level, slice: slice, withBytes: bytes, bytesPerRow: bytesPerRow,bytesPerImage: bytePerImage)
            
        }
        
        public static func createColorTexture(width:Int,
                                              height:Int,render:Renderer) throws ->Texture{
            return try Texture(width: width, 
                               height: height,
                               pixel: Configuration.ColorPixelFormat,
                               storeMode: .private,
                               usage: [.renderTarget,.shaderRead],
                               render: render)
        }
        public static func createDepthTexture(width:Int,
                                              height:Int,render:Renderer) throws ->Texture{
            return try Texture(width: width, 
                               height: height,
                               pixel: Configuration.DepthpixelFormat, 
                               storeMode: .private,
                               usage: [.renderTarget,.shaderRead,.shaderWrite],
                               render: render)
        }
        public static func createDepthStencilTexture(width:Int,
                                              height:Int,render:Renderer) throws ->Texture{
            return try Texture(width: width, 
                               height: height,
                               pixel: Configuration.DepthStencilpixelFormat,
                               storeMode: .private, 
                               usage: [.renderTarget,.shaderRead],
                               render: render)
        }
    }
    public class RenderQueue{
        public var renderer:Renderer{
            Renderer(device: queue.device)
        }
        public var queue:MTLCommandQueue
        public init(renderer: Renderer = .shared) throws {
            guard let queue = renderer.device.makeCommandQueue() else { throw TRError.createObjectFail("create queue fail")}
            self.queue = queue
        }
        public static let shared:RenderQueue = try! RenderQueue(renderer: .shared)
        
        public func createBuffer()throws ->MTLCommandBuffer{
            guard let buffer = self.queue.makeCommandBuffer() else {
                throw TRError.createObjectFail("create command buffer fail")
            }
            return autoreleasepool{buffer}
        }
        
        public func createCompute(buffer:MTLCommandBuffer,callback:(MTLComputeCommandEncoder)->Void)throws{
            guard let encoder = buffer.makeComputeCommandEncoder() else { throw TRError.createObjectFail("create compute encoder fail")}
            callback(encoder);
            encoder.endEncoding()
            buffer.commit()
        }
        public func blit(buffer:MTLCommandBuffer,from:MTLTexture,to:MTLTexture){
            let encoder = buffer.makeBlitCommandEncoder()
            encoder?.copy(from: from, to: to)
        }
    }
    public class Vsync:NSObject{
        public typealias VsyncCallBack = ()->Bool
        private var callback:VsyncCallBack?
        public override init(){
            super.init()
        }
        public func setCallBack(callback: @escaping ()->Bool) {
            self.callback = callback
            Thread {
                let l = CADisplayLink(target: self, selector: #selector(self.callbackSelector(link:)))
                l.add(to: RunLoop.current, forMode: .common)
                RunLoop.current.run()
            }.start()
        }
        @objc func callbackSelector(link:CADisplayLink){
            guard let callback else { return }
            if !callback(){
                link.invalidate()
            }
        }
    }
}

public class RenderPass{
    public var descriptor = MTLRenderPassDescriptor()
    public var drawable:CAMetalDrawable?
    public var render:Renderer
    public var width:Int{
        self.texture?.width ?? 0
    }
    public var height:Int{
        self.texture?.height ?? 0
    }
    public var texture:MTLTexture?{
        didSet{
            self.descriptor.colorAttachments[0].texture = texture
        }
    }
    public var depthTexture:MTLTexture?{
        didSet{
            self.descriptor.depthAttachment.texture = depthTexture
        }
    }
    
    public var stencilTexture:MTLTexture?{
        didSet{
            self.descriptor.stencilAttachment.texture = stencilTexture
        }
    }
    
    public init(render:Renderer){
        self.render = render
    }
    public func beginRender(buffer:MTLCommandBuffer,layer:CAMetalLayer) throws ->MTLRenderCommandEncoder{
        guard let drawable = layer.nextDrawable() else { throw TRError.createObjectFail("next drawable fail")}
        self.drawable = autoreleasepool { drawable }
        return try self.beginRender(buffer: buffer, texture: drawable.texture)
    }
    
    public func beginRender(buffer:MTLCommandBuffer,texture:MTLTexture) throws ->MTLRenderCommandEncoder{
        self.descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        self.descriptor.colorAttachments[0].loadAction = .clear
        self.descriptor.colorAttachments[0].storeAction = .store
        self.texture = texture
        self.descriptor.depthAttachment.clearDepth = 1;
        self.descriptor.depthAttachment.loadAction = .clear
        self.descriptor.stencilAttachment.clearStencil = 1;
        self.descriptor.stencilAttachment.loadAction = .clear
        if(self.depthTexture == nil){
            self.depthTexture = try Renderer.Texture.createDepthStencilTexture(width: self.width, height: self.height, render: self.render).texture
            self.stencilTexture = self.depthTexture
        }else if(self.width != self.depthTexture?.width && self.height != self.depthTexture?.height){
            self.depthTexture = try Renderer.Texture.createDepthStencilTexture(width: self.width, height: self.height, render: self.render).texture
            self.stencilTexture = self.depthTexture
        }
        
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else { throw TRError.createObjectFail("create computer encoder")}
        return encoder
    }
    public func beginNoDepth(buffer:MTLCommandBuffer,texture:MTLTexture) throws ->MTLRenderCommandEncoder{
        self.descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        self.descriptor.colorAttachments[0].loadAction = .clear
        self.descriptor.colorAttachments[0].storeAction = .store
        self.texture = texture
        self.depthTexture = nil
        self.stencilTexture = nil
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else { throw TRError.createObjectFail("create computer encoder")}
        return encoder
    }
    
    public func beginDepth(buffer:MTLCommandBuffer,width:Int,height:Int) throws ->MTLRenderCommandEncoder{
        
        if(width != self.depthTexture?.width && height != self.depthTexture?.height){
            self.depthTexture = try Renderer.Texture.createDepthTexture(width: width, height: height, render: self.render).texture
            self.descriptor.depthAttachment.clearDepth = 1;
            self.descriptor.depthAttachment.slice = 0;
            self.descriptor.depthAttachment.loadAction = .clear
            self.descriptor.depthAttachment.storeAction = .store
        }
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else { throw TRError.createObjectFail("create computer encoder")}
        encoder.setDepthBias(0, slopeScale: 0, clamp: 0)
        return encoder
    }
    
    public func clearTexture(){
        self.texture = nil
        self.depthTexture = nil
        self.stencilTexture = nil
    }
    public func setViewPort(encoder:MTLRenderCommandEncoder){
        encoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(self.width), height: Double(self.height), znear: 0, zfar: 1))
    }
}

public struct Model{
    public struct IndexModel{
        public var primitiveType:MTLPrimitiveType
        public var indexCount: Int
        public var indexType: MTLIndexType
        public var indexBuffer: MTLBuffer
        public var indexBufferOffset: Int
        public init(primitiveType: MTLPrimitiveType, indexCount: Int, indexType: MTLIndexType, indexBuffer: MTLBuffer, indexBufferOffset: Int) {
            self.primitiveType = primitiveType
            self.indexCount = indexCount
            self.indexType = indexType
            self.indexBuffer = indexBuffer
            self.indexBufferOffset = indexBufferOffset
        }
        public init(submesh:MTKSubmesh){
            self.primitiveType = submesh.primitiveType
            self.indexType = submesh.indexType
            self.indexBuffer = submesh.indexBuffer.buffer
            self.indexCount = submesh.indexCount
            self.indexBufferOffset = submesh.indexBuffer.offset
        }
    }
    public struct  VertexModel{
        public var offset:Int
        public var length:Int
        public var buffer:MTLBuffer
        public init(offset: Int, length: Int, buffer: MTLBuffer) {
            self.offset = offset
            self.length = length
            self.buffer = buffer
        }
        public init(buffer:MTKMeshBuffer){
            self.init(offset: buffer.offset, length: buffer.length, buffer: buffer.buffer)
        }
    }
    
    public var mapVertexBuffer:[Int:VertexModel] = [:]
    public var indexBuffers:[IndexModel] = []
    public var vertexCount:Int = 0
    public var globalPrimitiveType:MTLPrimitiveType = .triangle
    public var vertexDescription:MTLVertexDescriptor?
    public var modelObject:ModelObject = ModelObject(model: .identity, normal_model: .identity, shiness: 128)
    public init(mesh:MTKMesh){
        mapVertexBuffer[Int(model_vertex_buffer_index)] = VertexModel(buffer: mesh.vertexBuffers[0])
        mapVertexBuffer[Int(model_vertex_tan_buffer_index)] = VertexModel(buffer: mesh.vertexBuffers[1])
        mapVertexBuffer[Int(model_vertex_bitan_buffer_index)] = VertexModel(buffer: mesh.vertexBuffers[2])
        self.indexBuffers = mesh.submeshes.map({ i in
            IndexModel(submesh: i)
        })
        self.loadMesh(mesh: mesh)
    }
    public mutating func loadMesh(mesh:MTKMesh){
        self.vertexCount = mesh.vertexCount
        self.globalPrimitiveType = .triangle
        
        let vd = MTLVertexDescriptor()
        if let layout = mesh.vertexDescriptor.layouts[0] as? MDLVertexBufferLayout{
            let index = Int(model_vertex_buffer_index)
            vd.attributes[0].format = .float3
            vd.attributes[0].offset = 0
            vd.attributes[0].bufferIndex = index
            vd.attributes[1].format = .float3
            vd.attributes[1].offset = 12
            vd.attributes[1].bufferIndex = index
            vd.attributes[2].format = .float2
            vd.attributes[2].offset = 24
            vd.attributes[2].bufferIndex = index
            vd.layouts[index].stride = layout.stride
            vd.layouts[index].stepRate = 1
            vd.layouts[index].stepFunction = .perVertex
        }
        
        if let tanLayout = mesh.vertexDescriptor.layouts[1] as? MDLVertexBufferLayout ,tanLayout.stride > 0 {
            let index = Int(model_vertex_tan_buffer_index)
            vd.attributes[3].bufferIndex = index;
            vd.attributes[3].format = .float3;
            vd.attributes[3].offset = 0;
            vd.layouts[index].stride = tanLayout.stride
            vd.layouts[index].stepRate = 1
            vd.layouts[index].stepFunction = .perVertex
        }
        
        if let tanLayout = mesh.vertexDescriptor.layouts[2] as? MDLVertexBufferLayout ,tanLayout.stride > 0 {
            let index = Int(model_vertex_bitan_buffer_index)
            vd.attributes[4].bufferIndex = index;
            vd.attributes[4].format = .float3;
            vd.attributes[4].offset = 0;
            vd.layouts[index].stride = tanLayout.stride
            vd.layouts[index].stepRate = 1
            vd.layouts[index].stepFunction = .perVertex
        }
        
        self.vertexDescription = vd
    }
    public func draw(encoder:MTLRenderCommandEncoder){
        mapVertexBuffer.forEach { i in
            encoder.setVertexBuffer(i.value.buffer, offset: i.value.offset, index: i.key)
        }
        if indexBuffers.count > 0 {
            indexBuffers.forEach { sm in
                encoder.drawIndexedPrimitives(type: sm.primitiveType, indexCount: sm.indexCount, indexType: sm.indexType, indexBuffer: sm.indexBuffer, indexBufferOffset: sm.indexBufferOffset)
            }
        }else{
            encoder.drawPrimitives(type: globalPrimitiveType, vertexStart: 0, vertexCount: vertexCount)
        }
    }
}

public class RenderPipelineProgram{
    
    public private (set)var state:MTLRenderPipelineState?
    
    public let renderDescriptor:MTLRenderPipelineDescriptor
    
    public let shader:Renderer.Shader
    
    public init(shader:Renderer.Shader = .shared){
        self.shader = shader
        self.renderDescriptor = MTLRenderPipelineDescriptor()
    }
    public func reload(vertexDescription:MTLVertexDescriptor?,
                vertexFunction:String,
                fragmentFunction:String,
                shader:Renderer.Shader = .shared) throws {
        renderDescriptor.reset()
        renderDescriptor.colorAttachments[0].pixelFormat = Configuration.ColorPixelFormat
        renderDescriptor.colorAttachments[0].isBlendingEnabled = true;
        renderDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        renderDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusBlendAlpha
        renderDescriptor.vertexDescriptor = vertexDescription
        renderDescriptor.depthAttachmentPixelFormat = Configuration.DepthStencilpixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = Configuration.DepthStencilpixelFormat
        renderDescriptor.vertexFunction =  try shader.createFunction(functionName: vertexFunction)
        renderDescriptor.fragmentFunction = try shader.createFunction(functionName: fragmentFunction)

        self.state = try shader.render.device.makeRenderPipelineState(descriptor: renderDescriptor)
    }
    public func reloadRenderShadow(vertexDescription:MTLVertexDescriptor?,
                vertexFunction:String) throws {
        renderDescriptor.reset()
        renderDescriptor.colorAttachments[0].pixelFormat = .invalid
        renderDescriptor.colorAttachments[0].isBlendingEnabled = false
        renderDescriptor.vertexDescriptor = vertexDescription
        renderDescriptor.depthAttachmentPixelFormat = Configuration.DepthpixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = .invalid
        renderDescriptor.vertexFunction =  try shader.createFunction(functionName: vertexFunction)
        self.state = try shader.render.device.makeRenderPipelineState(descriptor: renderDescriptor)
    }
    public func reload(vertexFunction:String,
                fragmentFunction:String) throws {
        renderDescriptor.reset()
        renderDescriptor.colorAttachments[0].pixelFormat = Configuration.ColorPixelFormat
        renderDescriptor.vertexFunction =  try shader.createFunction(functionName: vertexFunction)
        renderDescriptor.fragmentFunction = try shader.createFunction(functionName: fragmentFunction)

        self.state = try shader.render.device.makeRenderPipelineState(descriptor: renderDescriptor)
    }
}
public class TileRenderPipelineProgram{
    
    public private (set)var state:MTLRenderPipelineState?
    
    public let renderDescriptor:MTLTileRenderPipelineDescriptor
    
    public let shader:Renderer.Shader
    
    public init(shader:Renderer.Shader = .shared){
        self.shader = shader
        self.renderDescriptor = MTLTileRenderPipelineDescriptor()
    }
    
    
    
    public func reload(functionName:String,
                       rasterSampleCount:Int) throws {
        renderDescriptor.reset()
        renderDescriptor.tileFunction = try shader.createFunction(functionName: functionName)
        renderDescriptor.rasterSampleCount = rasterSampleCount
        renderDescriptor.threadgroupSizeMatchesTileSize = true
        renderDescriptor.maxTotalThreadsPerThreadgroup = 16
        self.state = try shader.render.device.makeRenderPipelineState(tileDescriptor: renderDescriptor, options: []).0
    }
}

public class ComputePipelineProgram{
    public let state:MTLComputePipelineState
    public init(descriptor:MTLComputePipelineDescriptor,
                functionName:String,
                shader:Renderer.Shader = .shared) throws {
        let function = try shader.createFunction(functionName: functionName)
        self.state = try shader.render.device.makeComputePipelineState(function: function)
    }
}



