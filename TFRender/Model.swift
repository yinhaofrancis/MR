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
    public func begin(encoder:MTLRenderCommandEncoder){
        if let state = program.state{
            encoder.setRenderPipelineState(state)
            encoder.setDepthStencilState(depthState)
            encoder.setCullMode(self.cullModel)
        }
    }
    public func bindScene(encoder:MTLRenderCommandEncoder,
                        cameraModel:Camera,
                          lightModel:Light){
        var cameraData = cameraModel.cameraObject
        var lightObject = lightModel.lightObject
        encoder.setVertexBytes(&cameraData, length: MemoryLayout.size(ofValue: cameraData), index: Int(camera_object_buffer_index))
        encoder.setVertexBytes(&lightObject, length: MemoryLayout.size(ofValue: lightObject), index: Int(light_object_buffer_index))
        encoder.setFragmentBytes(&cameraData, length: MemoryLayout.size(ofValue: cameraData), index: Int(camera_object_buffer_index))
        encoder.setFragmentBytes(&lightObject, length: MemoryLayout.size(ofValue: lightObject), index: Int(light_object_buffer_index))
    }
    
    public mutating func draw(
        encoder:MTLRenderCommandEncoder,
        model:Model,
        material:Material,
        shadow:Shadow) throws{
            var modelObject = model.modelObject
            modelObject.createNormalMatrix()
            encoder.setVertexBytes(&modelObject, length: MemoryLayout.size(ofValue: modelObject), index: Int(model_object_buffer_index))
            
            encoder.setFragmentBytes(&modelObject, length: MemoryLayout.size(ofValue: modelObject), index: Int(model_object_buffer_index))
            
            encoder.setFragmentTexture(material.diffuse?.texture, index: Int(phong_diffuse_index))
            encoder.setFragmentTexture(material.specular?.texture, index: Int(phong_specular_index))
            encoder.setFragmentTexture(material.normal?.texture, index: Int(phong_normal_index))
            encoder.setFragmentTexture(shadow.globelShadow, index: Int(shadow_map_index))
            encoder.setFragmentSamplerState(material.diffuse?.sampler.samplerState, index: Int(sampler_defalut))
            encoder.setFragmentSamplerState(Renderer.Sampler.defaultShadowSampler.samplerState, index: Int(shadow_sampler_default))
            model.draw(encoder: encoder)
    }
}

public struct RenderShadowModel{
    let program = RenderPipelineProgram()
    public var cullModel = MTLCullMode.back
    public var depthState:MTLDepthStencilState
    public init(vertexDescriptor:MTLVertexDescriptor?,
                depth:MTLDepthStencilState)throws{
        try program.reloadRenderShadow(vertexDescription:vertexDescriptor, vertexFunction: "VertexShadowRender")
        self.depthState = depth
    }
    public func begin(encoder:MTLRenderCommandEncoder){
        if let state = program.state{
            encoder.setRenderPipelineState(state)
            encoder.setDepthStencilState(depthState)
            encoder.setCullMode(self.cullModel)
        }
    }
    public func bindScene(encoder:MTLRenderCommandEncoder,
                        cameraModel:Camera,
                          lightModel:Light){
        var cameraData = cameraModel.cameraObject
        var lightObject = lightModel.lightObject
        encoder.setVertexBytes(&cameraData, length: MemoryLayout.size(ofValue: cameraData), index: Int(camera_object_buffer_index))
        encoder.setVertexBytes(&lightObject, length: MemoryLayout.size(ofValue: lightObject), index: Int(light_object_buffer_index))
    }
    public mutating func draw(
        encoder:MTLRenderCommandEncoder,
        model:Model) throws{
            var modelObject = model.modelObject
            
            modelObject.createNormalMatrix()
            encoder.setVertexBytes(&modelObject, length: MemoryLayout.size(ofValue: modelObject), index: Int(model_object_buffer_index))
            
            
            model.draw(encoder: encoder)
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
    public func begin(encoder:MTLRenderCommandEncoder){
        if let state = program.state{
            encoder.setRenderPipelineState(state)
            encoder.setDepthStencilState(depthState)
            encoder.setCullMode(self.cullModel)
        }
    }
    public func bindScene(encoder:MTLRenderCommandEncoder,
                          cameraModel:Camera,
                          lightModel:Light){
        var cameraData = cameraModel.cameraObject
        var lightObject = lightModel.lightObject
        encoder.setVertexBytes(&cameraData, length: MemoryLayout.size(ofValue: cameraData), index: Int(camera_object_buffer_index))
        encoder.setVertexBytes(&lightObject, length: MemoryLayout.size(ofValue: lightObject), index: Int(light_object_buffer_index))
    }
    public mutating func draw(
        encoder:MTLRenderCommandEncoder,
        material:Material) throws{
            var modelObject = model.modelObject
            
            modelObject.createNormalMatrix()
            encoder.setVertexBytes(&modelObject, length: MemoryLayout.size(ofValue: modelObject), index: Int(model_object_buffer_index))
            
            encoder.setFragmentTexture(material.ambient?.texture, index: Int(phong_ambient_index))
            encoder.setFragmentSamplerState(material.ambient?.sampler.samplerState, index: 0)
            model.draw(encoder: encoder)
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
    public static func model(url:URL,index:Int,render:Renderer = .shared) throws ->Model{
        let ass = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: render.device))
        return try model(asset: ass, index: index, render: render)
    }
    public static func model(asset:MDLAsset,index:Int,render:Renderer = .shared) throws ->Model{
    
        let a = try MTKMesh.newMeshes(asset: asset, device: render.device)
        let md = a.modelIOMeshes[index]
        md.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
        return Model(mesh: try! MTKMesh(mesh: md, device: render.device))
    }

}

public struct Asset{
    let asset:MDLAsset
    let render:Renderer
    public init(asset: MDLAsset,render:Renderer = .shared) {
        self.asset = asset
        self.render = render
    }
    public init(url:URL,render:Renderer = .shared){
        self.init(asset: MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: render.device)),render: render)
    }
    private func model(asset:MDLAsset,index:Int,render:Renderer = .shared) throws ->Model{
        let a = try MTKMesh.newMeshes(asset: asset, device: render.device)
        let md = a.modelIOMeshes[index]
        md.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
        return Model(mesh: try! MTKMesh(mesh: md, device: render.device))
    }
    public func model(index:Int)throws ->Model{
        return try self.model(asset: asset, index: index)
    }

    public var models:[MDLMesh]?{
        return asset.childObjects(of: MDLMesh.self) as? [MDLMesh]
    }
    public var skeleton:[MDLSkeleton]?{
        return asset.childObjects(of: MDLSkeleton.self) as? [MDLSkeleton]
    }
    public var camera:[MDLCamera]?{
        return asset.childObjects(of: MDLCamera.self) as? [MDLCamera]
    }
    public var light:[MDLLight]?{
        return asset.childObjects(of: MDLLight.self) as? [MDLLight]
    }
    public var animation:[MDLPackedJointAnimation]?{
        return asset.childObjects(of: MDLPackedJointAnimation.self) as? [MDLPackedJointAnimation]
    }
}


extension ModelObject{
    public mutating func createNormalMatrix(){
        self.normal_model = simd_float4x4.inverseTranspose(m: self.model)
    }
}

public struct Camera{
    
    public var cameraObject:CameraObject = CameraObject(projection: simd_float4x4.perspectiveRH_ZO(fovy: 45, aspect: 9.0 / 16.0, zNear: 1, zFar: 150), view: .lookat(eye: [8,8,8], center: [0,0,0], up: [0,1,0]), camera_pos: [8,8,8], maxBias: 0.00001)
    
    public init() {
        self.updateView()
        self.updateProjection()
    }
    
    public var lookTo:simd_float3 = [0,0,0]{
        didSet{
            self.updateView()
        }
    }
    public var maxBias:Float = 0.001
    
    public var position:simd_float3 = [8,8,8]{
        didSet{
            self.updateView()
        }
    }
    
    public var up:simd_float3 = [0,1,0]{
        didSet{
            self.updateView()
        }
    }
    
    public var aspect:Float = 9.0 / 16.0{
        didSet{
            self.updateProjection()
        }
    }
    
    public var fovy:Float = 45{
        didSet{
            self.updateProjection()
        }
    }
    
    public var near:Float = 1{
        didSet{
            self.updateProjection()
        }
    }
    
    public var far:Float = 50{
        didSet{
            self.updateProjection()
        }
    }
    
    mutating func updateProjection(){
        self.cameraObject.projection = simd_float4x4.perspectiveRH_NO(fovy: fovy, aspect: aspect, zNear: near, zFar: far)
    }
    mutating func updateView(){
        self.cameraObject.view = float4x4.lookat(eye: position, center: lookTo, up: up)
        self.cameraObject.camera_pos = position
        self.cameraObject.maxBias = self.maxBias
    
    }
    public static var ndc:[simd_float3] = [
        [-1,-1,-1],
        [ 1,-1,-1],
        [-1, 1,-1],
        [ 1, 1,-1],
        [-1,-1, 1],
        [ 1,-1, 1],
        [-1, 1, 1],
        [ 1, 1, 1],
    ]
    public var frustum:[simd_float3]{
        let inView = self.cameraObject.view.inverse
        let inProject = self.cameraObject.projection.inverse
        return Camera.ndc.map { vt in
            inView * inProject * simd_float4(vt, 1)
        }.map { t in
            simd_float3(t.x,t.y,t.z) / t.w;
        }
    }
    public var aabb:AABB{
        var a = AABB()
        self.frustum.forEach { s in
            a.add(v: s)
        }
        return a
    }
}

public struct Light{
   
    public var lightObject:LightObject
    
    public init() {
        self.lightObject = LightObject(light_pos: [-8,8,8],
                                       light_center: [0,0,0],
                                       is_point_light:  0,
                                       projection: .identity,
                                       view: .identity)
        self.updateView()
        self.updateProjection()
    }
    
    public var width:Float = 10{
        didSet{
            self.updateProjection()
        }
    }
    
    public var height:Float = 10{
        didSet{
            self.updateProjection()
        }
    }
    
    public var position:simd_float3 = [-8,8,8]{
        didSet{
            self.updateView()
        }
    }
    
    public var target:simd_float3 = [0,0,0]{
        didSet{
            self.updateView()
        }
    }
    
    public var up:simd_float3 = [0,1,0]{
        didSet{
            self.updateView()
        }
    }
    
    public var near:Float = 1{
        didSet{
            self.updateProjection()
        }
    }
    
    public var far:Float = 150{
        didSet{
            self.updateProjection()
        }
    }
    
    
    mutating func updateView(){
        self.lightObject.light_pos = position
        self.lightObject.light_center = target
        self.lightObject.view = float4x4.lookat(eye: position, center: target, up: up)
    }
    mutating func updateProjection(){

        self.lightObject.projection = float4x4.orthoRH_ZO(left: -width, right: width, bottom: -height, top: height,zNear: near,zFar: far)
    }
    public var frustum:[simd_float3]{
        let inView = self.lightObject.view.inverse
        let inProject = self.lightObject.projection.inverse
        return Camera.ndc.map { vt in
            inView * inProject * simd_float4(vt, 1)
        }.map { t in
            simd_float3(t.x,t.y,t.z) / t.w;
        }
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
    public func texture(url:URL,callback:@escaping (Renderer.Texture?)->Void){
        do{
            let s = try textureLoader.newTexture(URL: url,options: [.origin:MTKTextureLoader.Origin.bottomLeft])
            callback(Renderer.Texture(texture: s, samplerState: Renderer.Sampler.defaultSampler.samplerState))
        }catch{
            callback(nil)
        }
        
    }
}
