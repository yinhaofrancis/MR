//
//  File.swift
//  MR
//
//  Created by wenyang on 2023/12/10.
//

import Metal
import MetalKit
import simd
import Foundation

public protocol RenderBuffer{
    var modelBuffer:MTLBuffer{ get }
}

public protocol Renderable{
    
    var vertexShader:String { get }
    
    var fragmentShader:String { get }
    
    var vertexDesciption:MTLVertexDescriptor? { get }
    
    var depthStencilDescriotion:MTLDepthStencilDescriptor? { get }
    
    var cullMode:MTLCullMode { get }
    
    var renderPiplineState:MTLRenderPipelineState? { get set }
    
    var depthStencilState:MTLDepthStencilState? { get set }
    
    func draw(encoder:MTLRenderCommandEncoder)
    
}



extension AL {
    public struct SubModel{
        public var primitiveType:MTLPrimitiveType
        public var indexCount: Int
        public var indexType: MTLIndexType
        public var indexBuffer: MTLBuffer
        public var indexBufferOffset: Int
    }
    
    public class Model<T>:Renderable{
        
        public var model: UnsafeMutablePointer<T> = .allocate(capacity: 1)
        
        
        public var cullMode: MTLCullMode = .none
        
        
        
        public var depthStencilState: MTLDepthStencilState?
        
        public var depthStencilDescriotion: MTLDepthStencilDescriptor?
        
        
        public var vertexShader: String
        
        public var fragmentShader: String
        
        public var vertexBuffer     :[MTLBuffer] = []
        
        public var indexBuffer      :[AL.SubModel] = []
        
        public var primitiveType    :MTLPrimitiveType = .triangle
        
        public var ambient          :AL.Texture?
        
        public var diffuse          :AL.Texture?
        
        public var normal           :AL.Texture?
        
        public var specular         :AL.Texture?
        
        public var vertexCount       :Int = 0
        
        public var renderPiplineState:MTLRenderPipelineState?
        
        public var vertexDesciption:MTLVertexDescriptor?
        
        
        
        public init(vertexShader: String,fragmentShader: String){
            self.vertexShader = vertexShader
            self.fragmentShader = fragmentShader
        }
        
        func loadMesh(mesh:MTKMesh){
            self.indexBuffer = mesh.submeshes.map({ i in
                SubModel(primitiveType: i.primitiveType, indexCount: i.indexCount, indexType: i.indexType, indexBuffer: i.indexBuffer.buffer, indexBufferOffset: i.indexBuffer.offset)
            })
            self.vertexBuffer = mesh.vertexBuffers.map({$0.buffer})
            self.vertexCount = mesh.vertexCount
            self.primitiveType = .triangle
            
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
            
            self.vertexDesciption = vd
        }
        
        public func draw(encoder:MTLRenderCommandEncoder){
            guard let renderPiplineState else { return }
            guard self.vertexBuffer.count > 0 else { return }
            encoder.setRenderPipelineState(renderPiplineState)
            if let ds = self.depthStencilState {
                encoder.setDepthStencilState(ds)
            }
            encoder.setCullMode(self.cullMode)
            encoder.setVertexBytes(self.model, length: MemoryLayout.size(ofValue: self.model.pointee), index: Int(model_object_buffer_index))
            encoder.setFragmentBytes(self.model, length: MemoryLayout.size(ofValue: self.model.pointee), index: Int(model_object_buffer_index))
            for i in 0 ..< self.vertexBuffer.count{
                encoder.setVertexBuffer(self.vertexBuffer[i], offset: 0, index: Int(model_vertex_buffer_index) + i)
            }

            encoder.setFragmentTextures([
                diffuse?.texture,
                specular?.texture,
                normal?.texture,
                ambient?.texture,
            ], range: Int(phong_diffuse_index) ..< Int(phong_ambient_index) + 1)
            encoder.setFragmentSamplerStates([
                
                diffuse?.samplerState,
                specular?.samplerState,
                normal?.samplerState,
                ambient?.samplerState,
            ], range: Int(phong_diffuse_index) ..< Int(phong_ambient_index) + 1)
            if indexBuffer.count > 0 {
                for i in indexBuffer {
                    encoder.drawIndexedPrimitives(type: i.primitiveType,
                                                  indexCount: i.indexCount,
                                                  indexType: i.indexType,
                                                  indexBuffer: i.indexBuffer,
                                                  indexBufferOffset: i.indexBufferOffset)
                }
            }else{
                encoder.drawPrimitives(type: primitiveType,
                                       vertexStart: 0,
                                       vertexCount: vertexCount)
            }
        }
    }
}
extension AL.Model where T == ModelObject{
    public func loadModel(){
        self.model.pointee.normal_model = simd_float4x4.inverseTranspose(m: model.pointee.model)
    }
}
