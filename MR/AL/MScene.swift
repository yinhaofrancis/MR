//
//  MScene.swift
//  MR
//
//  Created by wenyang on 2023/12/10.
//

import Metal
import MetalKit
import simd
import Foundation

extension AL{
    
    public class Scene<T>:RenderBuffer{
        
        public var model: UnsafeMutablePointer<T> = .allocate(capacity: 1)
        
        public var camera:Camera = Camera()
        
        public var light:Light = Light()
        
        public var modelBuffer: MTLBuffer
        
        public var renderables:[Renderable] = []
        
        
        public func draw(encoder:MTLRenderCommandEncoder){
           
            encoder.setVertexBuffer(self.modelBuffer, offset: 0, index: Int(camera_object_buffer_index))
            encoder.setFragmentBuffer(self.modelBuffer, offset: 0, index: Int(camera_object_buffer_index))
            for i in renderables {
                i.draw(encoder: encoder)
            }
        }
        
        public var render:AL.Render
        
        public init(render:AL.Render) {
            self.render = render
            self.modelBuffer = render.device.makeBuffer(length: MemoryLayout<T>.size)!
        }
        public func loadBuffer(){
            self.modelBuffer.contents().copyMemory(from: self.model, byteCount: MemoryLayout<T>.size)
        }
    }
    public struct Light{
       
        public var point_light:Bool = false
        
        public var projection:simd_float4x4 = .identity
        
        public var view:simd_float4x4 = .identity
        public init() {
            self.updateView()
            self.updateProjection()
        }
        
        public var width:Float = 1024{
            didSet{
                self.updateProjection()
            }
        }
        
        public var height:Float = 1024{
            didSet{
                self.updateProjection()
            }
        }
        
        public var position:simd_float3 = [3,3,3]{
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
        
        mutating func updateView(){
            self.view = float4x4.lookat(eye: position, center: target, up: up)
        }
        mutating func updateProjection(){
            self.projection = float4x4.ortho(left: -width, right: width, bottom: -height, top: height)
        }
    }

    public struct Camera{
        
        public var projection:simd_float4x4 = .identity
        
        public var view:simd_float4x4 = .identity
        
        public init() {
            self.updateView()
            self.updateProjection()
        }
        
        public var lookTo:simd_float3 = [0,0,0]{
            didSet{
                self.updateView()
            }
        }
        
        public var position:simd_float3 = [1,0,1]{
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
        
        public var far:Float = 2000{
            didSet{
                self.updateProjection()
            }
        }
        
        mutating func updateProjection(){
            self.projection = simd_float4x4.perspective(fovy: fovy, aspect: aspect, zNear: near, zFar: far)
        }
        mutating func updateView(){
            self.view = float4x4.lookat(eye: position, center: lookTo, up: up)
        }
    }

    
}

extension AL.Scene where T == CameraObject{
    
    public func loadModel(){
        self.model.pointee.camera_pos = self.camera.position
        self.model.pointee.light_pos = self.light.position;
        self.model.pointee.light_center = self.light.target;
        self.model.pointee.is_point_light = self.light.point_light ? 1 : 0;
        self.model.pointee.view = self.camera.view
        self.model.pointee.projection = self.camera.projection
        self.loadBuffer()
    }
}


public protocol Viewable{
    var projection:simd_float4x4 { get }
    
    var view:simd_float4x4 { get }
    
    var direction:simd_float3 { get }
}

public struct TextureRender{
    
    public var state:MTLRenderPipelineState
    public var shader:AL.Shader
    public init(shader: AL.Shader) {
        self.shader = shader
        self.state = try! shader.createCopyScreenPiplineState()
    }
    public func render(buffer:MTLCommandBuffer,renderPass:AL.RenderPass,texture:AL.Texture?,layer:CAMetalLayer){
        self.render(buffer: buffer, renderPass: renderPass, texture: texture?.texture, sampleState: texture?.samplerState, layer: layer)
    }
    
    
    public func render(buffer:MTLCommandBuffer,
                       renderPass:AL.RenderPass,
                       texture:MTLTexture?,
                       sampleState:MTLSamplerState? = nil,
                       layer:CAMetalLayer){
        let encoder = renderPass.beginColorRender(buffer: buffer, layer: layer)
        guard let drawable = renderPass.drawable else { return }
        encoder?.setRenderPipelineState(self.state)
        encoder?.setFragmentTexture(texture, index: 0);
        encoder?.setFragmentSamplerState(sampleState ?? self.shader.render.defaultSampler, index: 0)
        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder?.endEncoding()
        buffer.present(drawable)
    }
}
