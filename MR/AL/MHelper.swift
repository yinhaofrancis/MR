//
//  MHelper.swift
//  MR
//
//  Created by wenyang on 2023/12/10.
//

import Metal
import MetalKit
import simd
import Foundation


extension AL{
    public struct Helper{
        public var queue:Queue
        
        public var shader:Shader
        
        public var renderPass:RenderPass
        
        public var render:Render{
            return self.queue.render
        }
        
        public lazy var textureRender:TextureRender = TextureRender(shader: self.shader)
        
        
        public init(queue: Queue, shader: Shader,renderPass:RenderPass) {
            self.queue = queue
            self.shader = shader
            self.renderPass = renderPass
        }
        
        public static let shared:Helper = Helper(queue: AL.Queue.shared, shader: AL.Shader.shared, renderPass: AL.RenderPass.shared)
    }
}

extension AL.Shader{
    public func createRenderDisplayPiplineState<T:Renderable>(model:inout T)throws{
        
        let desc = MTLRenderPipelineDescriptor()
        desc.colorAttachments[0].pixelFormat = ColorPixel;
        desc.colorAttachments[0].isBlendingEnabled = true;
        desc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusBlendAlpha
        desc.depthAttachmentPixelFormat = DepthStencilPixel
        desc.stencilAttachmentPixelFormat = DepthStencilPixel
        desc.vertexFunction = self.lib.makeFunction(name: model.vertexShader)
        desc.fragmentFunction = self.lib.makeFunction(name: model.fragmentShader)
        desc.vertexDescriptor = model.vertexDesciption
        
        let state = try self.render.device.makeRenderPipelineState(descriptor: desc)
        model.renderPiplineState = state
        
        if let dep = model.depthStencilDescriotion{
            model.depthStencilState = self.render.device.makeDepthStencilState(descriptor: dep)
        }else{
            model.depthStencilState = self.render.defaultDepthState
        }
    }
    public func createCopyScreenPiplineState() throws ->MTLRenderPipelineState{
        let desc = MTLRenderPipelineDescriptor()
        desc.colorAttachments[0].pixelFormat = ColorPixel;
        desc.vertexFunction = self.lib.makeFunction(name: "VertexScreenDisplayRender")
        desc.fragmentFunction = self.lib.makeFunction(name: "FragmentScreenDisplayRender")
        return try self.render.device.makeRenderPipelineState(descriptor: desc)
    }
}

extension AL.Helper{
    public func plant(size:vector_float3)throws ->AL.Model<ModelObject>{
        var m = AL.Model<ModelObject>(vertexShader: "vertexPlainRender", fragmentShader: "fragmentPlainRender")
        let md = MDLMesh(planeWithExtent: size, segments: [30,30], geometryType: .triangles, allocator: MTKMeshBufferAllocator(device: render.device))

        md.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
        let mk = try! MTKMesh(mesh: md, device: render.device)
        m.loadMesh(mesh: mk)
        m.diffuse = self.render.gray;
        m.model.pointee.model = simd_float4x4.identity
        m.ambient = self.render.defaultAmbient;
        m.specular = render.defaultSpeclar;
        m.model.pointee.shiness = 128;
        m.normal = render.defaultNormal
//        m.cullMode = .
        try self.shader.createRenderDisplayPiplineState(model: &m)
        return m
    }
    
    public func ball(size:vector_float3)throws ->AL.Model<ModelObject>{
        var m = AL.Model<ModelObject>(vertexShader: "vertexPlainRender", fragmentShader: "fragmentPlainRender")
        
        m.diffuse = render.gray;
        m.model.pointee.model = simd_float4x4.identity
        m.ambient = render.defaultAmbient;
        m.specular = render.defaultSpeclar;
        m.normal = render.defaultNormal
        m.model.pointee.shiness = 128;
        m.cullMode = .front
        let md = MDLMesh(sphereWithExtent: size, segments: [15,15], inwardNormals: false, geometryType: .triangles, allocator:  MTKMeshBufferAllocator(device: render.device))

        md.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
        let mk = try! MTKMesh(mesh: md, device: render.device)
        m.loadMesh(mesh: mk)

        try self.shader.createRenderDisplayPiplineState(model: &m)
        return m
    }
    public func box(size:vector_float3)throws ->AL.Model<ModelObject>{
        var m = AL.Model<ModelObject>(vertexShader: "vertexPlainRender", fragmentShader: "fragmentPlainRender")
        m.model.pointee.shiness = 128;
        m.diffuse = render.gray;
        m.model.pointee.model = simd_float4x4.identity
        m.ambient = render.defaultAmbient;
        m.specular = render.defaultSpeclar;
        m.normal = render.defaultNormal
        m.cullMode = .front
        let md = MDLMesh(boxWithExtent: size, segments: [30,30,30], inwardNormals: false, geometryType: .triangles, allocator: MTKMeshBufferAllocator(device: render.device))

        md.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
        let mk = try! MTKMesh(mesh: md, device: render.device)
        m.loadMesh(mesh: mk)

        try self.shader.createRenderDisplayPiplineState(model: &m)
        return m
    }
    
    public func skybox(size:vector_float3,scale:Float)throws ->AL.Model<ModelObject>{
        var m = AL.Model<ModelObject>(vertexShader: "vertexSkyboxRender", fragmentShader: "fragmentSkyboxRender" )
        
        let md = MDLMesh(sphereWithExtent: size * scale, segments: [30,30], inwardNormals: true, geometryType: .triangles, allocator:  MTKMeshBufferAllocator(device: render.device))
        
        let mk = try! MTKMesh(mesh: md, device: render.device)
        m.loadMesh(mesh: mk)
        m.ambient = render.checkerboardCube;
        m.cullMode = .back
        try self.shader.createRenderDisplayPiplineState(model: &m)
        return m
    }
    
    public func makeTimer()->AL.Vsync{
        AL.Vsync()
    }
    public func makeScene()->AL.Scene<SceneObject>{
        return AL.Scene(render: render)
    }
}
