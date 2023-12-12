//
//  Model.swift
//  TFRender
//
//  Created by wenyang on 2023/12/12.
//

import Metal
import MetalKit
import simd
import Foundation



public struct RenderScreen{
    let program = RenderPipelineProgram()
    public init()throws{
        try program.reload(vertexFunction: "VertexScreenDisplayRender", fragmentFunction: "FragmentScreenDisplayRender")
    }
    public func draw(encoder:MTLRenderCommandEncoder,texture:Renderer.Texture) throws{
        if let state = program.state{
            encoder.setRenderPipelineState(state)
            encoder.setFragmentTexture(texture.texture, index: 0)
            encoder.setFragmentSamplerState(texture.sampler.samplerState, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
    }
}

public struct RenderModel{
    public var cullModel = MTLCullMode.front
    public var depthState:MTLDepthStencilState
    
    let program = RenderPipelineProgram()
    public init(vertexDescriptor:MTLVertexDescriptor?,depthState:MTLDepthStencilState)throws{
        try program.reload(vertexDescription:vertexDescriptor, vertexFunction: "vertexPlainRender", fragmentFunction: "fragmentPlainRender")
        self.depthState = depthState
    }
    
    public mutating func draw(
        encoder:MTLRenderCommandEncoder,
        model:Model,
        material:Material,
        cameraModel:inout CameraObject,
        lightModel:inout LightObject) throws{
        if let state = program.state{
            encoder.setRenderPipelineState(state)
            encoder.setDepthStencilState(depthState)
            var modelObject = model.modelObject
            modelObject.createNormalMatrix()
            encoder.setVertexBytes(&modelObject, length: MemoryLayout.size(ofValue: modelObject), index: Int(model_object_buffer_index))
            encoder.setVertexBytes(&cameraModel, length: MemoryLayout.size(ofValue: cameraModel), index: Int(camera_object_buffer_index))
            encoder.setVertexBytes(&lightModel, length: MemoryLayout.size(ofValue: lightModel), index: Int(light_object_buffer_index))
            encoder.setFragmentBytes(&modelObject, length: MemoryLayout.size(ofValue: modelObject), index: Int(model_object_buffer_index))
            encoder.setFragmentBytes(&cameraModel, length: MemoryLayout.size(ofValue: cameraModel), index: Int(camera_object_buffer_index))
            encoder.setFragmentBytes(&lightModel, length: MemoryLayout.size(ofValue: lightModel), index: Int(light_object_buffer_index))
            encoder.setCullMode(self.cullModel)
            encoder.setFragmentTexture(material.diffuse?.texture, index: Int(phong_diffuse_index))
            encoder.setFragmentTexture(material.specular?.texture, index: Int(phong_specular_index))
            encoder.setFragmentTexture(material.normal?.texture, index: Int(phong_normal_index))
            encoder.setFragmentSamplerState(material.diffuse?.sampler.samplerState, index: 0)
            model.draw(encoder: encoder)
        }
    }
}

public struct RenderSkyboxModel{
    let program = RenderPipelineProgram()
    public var model:Model
    public var cullModel = MTLCullMode.back
    public var depthState:MTLDepthStencilState
    public init(vertexDescriptor:MTLVertexDescriptor?,
                depth:MTLDepthStencilState,
                model:Model)throws{
        try program.reload(vertexDescription:vertexDescriptor, vertexFunction: "vertexSkyboxRender", fragmentFunction: "fragmentSkyboxRender")
        self.depthState = depth
        self.model = model
    }
    
    public mutating func draw(
        encoder:MTLRenderCommandEncoder,
        cameraModel:inout CameraObject,
        material:Material,
        lightModel:inout LightObject) throws{
        if let state = program.state{
            var modelObject = model.modelObject
            modelObject.createNormalMatrix()
            encoder.setRenderPipelineState(state)
            encoder.setDepthStencilState(depthState)
            encoder.setVertexBytes(&modelObject, length: MemoryLayout.size(ofValue: modelObject), index: Int(model_object_buffer_index))
            encoder.setVertexBytes(&cameraModel, length: MemoryLayout.size(ofValue: cameraModel), index: Int(camera_object_buffer_index))
            encoder.setVertexBytes(&lightModel, length: MemoryLayout.size(ofValue: lightModel), index: Int(light_object_buffer_index))
            encoder.setFragmentTexture(material.ambient?.texture, index: Int(phong_ambient_index))
            encoder.setFragmentSamplerState(material.ambient?.sampler.samplerState, index: 0)
            encoder.setCullMode(self.cullModel)
            model.draw(encoder: encoder)
        }
    }
}

extension Model{
    
    public static func sphere(size:simd_float3,segments:simd_uint2,render:Renderer = .shared)->Model{
        let md = MDLMesh(sphereWithExtent: size, segments:segments, inwardNormals: false, geometryType: .triangles, allocator:  MTKMeshBufferAllocator(device: render.device))

        md.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
        let mk = try! MTKMesh(mesh: md, device: render.device)
        return Model(mesh: mk)
    }
    
    public static func skybox(scale:Float,render:Renderer = .shared)->Model{
        let md = MDLMesh(sphereWithExtent: simd_float3(1, 1, 1) * scale, segments:[30,30], inwardNormals: true, geometryType: .triangles, allocator:  MTKMeshBufferAllocator(device: render.device))

        md.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
        let mk = try! MTKMesh(mesh: md, device: render.device)
        return Model(mesh: mk)
    }
    
    public static func box(size:simd_float3,segments:simd_uint3,render:Renderer = .shared)->Model{
        let md = MDLMesh(boxWithExtent: size, segments: segments, inwardNormals: false, geometryType: .triangles, allocator: MTKMeshBufferAllocator(device: render.device))
        md.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
        let mk = try! MTKMesh(mesh: md, device: render.device)
        return Model(mesh: mk)
    }
    
    public static func plant(size:simd_float3,segments:simd_uint2,render:Renderer = .shared)->Model{
        let md = MDLMesh(planeWithExtent: size, segments: segments, geometryType: .triangles, allocator: MTKMeshBufferAllocator(device: render.device))
        md.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
        let mk = try! MTKMesh(mesh: md, device: render.device)
        return Model(mesh: mk)
    }
    
}

extension ModelObject{
    public mutating func createNormalMatrix(){
        self.normal_model = simd_float4x4.inverseTranspose(m: self.model)
    }
}


public struct TextureLoader{

    public static let shared:TextureLoader = TextureLoader(render: Renderer.shared)
    
    public let textureLoader:MTKTextureLoader
    public let render:Renderer
    public init(render:Renderer){
        self.render = render
        textureLoader = MTKTextureLoader(device: render.device)
    }
    
    public func texture(name:String,callback:@escaping (Renderer.Texture?)->Void){
        textureLoader.newTexture(name: name, scaleFactor: 1, bundle: nil) { texture, e in
            if e == nil {
                callback(Renderer.Texture(texture: texture!, samplerState: Renderer.Sampler.defaultSampler.samplerState))
            }
        }
    }
}
