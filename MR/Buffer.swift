////
////  Buffer.swift
////  MR
////
////  Created by wenyang on 2023/12/8.
////
//
//import Metal
//import MetalKit
//import simd
//import Foundation
//
//
//
//extension MR {
//    
//    public struct SubModel{
//        public var primitiveType:MTLPrimitiveType
//        public var indexCount: Int
//        public var indexType: MTLIndexType
//        public var indexBuffer: MTLBuffer
//        public var indexBufferOffset: Int
//    }
//    
//    public class Model<T>:Renderable{
//        public var modelBuffer: MTLBuffer
//        
//        deinit{
//            model.deallocate()
//        }
//        public var model: UnsafeMutablePointer<T> = .allocate(capacity: 1)
//        
//        public typealias M = T
//        
//        public var cullMode: MTLCullMode = .none
//        
//        
//        
//        public var depthStencilState: MTLDepthStencilState?
//        
//        public var depthStencilDescriotion: MTLDepthStencilDescriptor?
//        
//        
//        public var vertexShader: String
//        
//        public var fragmentShader: String
//
//        public var vertexBuffer     :MTLBuffer?
//        
//        public var indexBuffer      :[SubModel] = []
//        
//        public var primitiveType    :MTLPrimitiveType = .triangle
//        
//        public var ambient          :MR.Render.Texture?
//        
//        public var diffuse          :MR.Render.Texture?
//        
//        public var normal           :MR.Render.Texture?
//        
//        public var specular         :MR.Render.Texture?
//        
//        public var vertexCount       :Int = 0
//        
//        public var renderPiplineState:MTLRenderPipelineState?
//        
//        public var vertexDesciption:MTLVertexDescriptor?
//        
//        
//        
//        public init(vertexShader: String,fragmentShader: String){
//            self.vertexShader = vertexShader
//            self.fragmentShader = fragmentShader
//        }
//        
//        func loadMesh(mesh:MTKMesh){
//            self.indexBuffer = mesh.submeshes.map({ i in
//                SubModel(primitiveType: i.primitiveType, indexCount: i.indexCount, indexType: i.indexType, indexBuffer: i.indexBuffer.buffer, indexBufferOffset: i.indexBuffer.offset)
//            })
//            self.vertexBuffer = mesh.vertexBuffers[0].buffer
//            self.vertexCount = mesh.vertexCount
//            self.primitiveType = .triangle
//
//            let vd = MTLVertexDescriptor()
//            vd.attributes[0].format = .float3
//            vd.attributes[0].offset = 0
//            vd.attributes[0].bufferIndex = 0
//            vd.attributes[1].format = .float3
//            vd.attributes[1].offset = 12
//            vd.attributes[1].bufferIndex = 0
//            vd.attributes[2].format = .float2
//            vd.attributes[2].offset = 24
//            vd.attributes[2].bufferIndex = 0
//            vd.layouts[0].stride = 32
//            vd.layouts[0].stepRate = 1
//            vd.layouts[0].stepFunction = .perVertex
//            self.vertexDesciption = vd
//        }
//        
//        public func draw(encoder:MTLRenderCommandEncoder?){
//            guard let encoder  else { return }
//            guard let renderPiplineState else { return }
//            guard let vb = self.vertexBuffer else { return }
//            encoder.setRenderPipelineState(renderPiplineState)
//            if let ds = self.depthStencilState {
//                encoder.setDepthStencilState(ds)
//            }
//            encoder.setCullMode(self.cullMode)
//            encoder.setVertexBytes(self.model, length: MemoryLayout.size(ofValue: self.model.pointee), index: Int(model_object_buffer_index))
//            encoder.setFragmentBytes(self.model, length: MemoryLayout.size(ofValue: self.model.pointee), index: Int(model_object_buffer_index))
//            
//            encoder.setVertexBuffer(vb, offset: 0, index: Int(model_vertex_buffer_index))
//            encoder.setFragmentTextures([
//                diffuse?.texture,
//                specular?.texture,
//                normal?.texture,
//                ambient?.texture,
//            ], range: Int(phong_diffuse_index) ..< Int(phong_ambient_index) + 1)
//            encoder.setFragmentSamplerStates([
//                
//                diffuse?.samplerState,
//                specular?.samplerState,
//                normal?.samplerState,
//                ambient?.samplerState,
//            ], range: Int(phong_diffuse_index) ..< Int(phong_ambient_index) + 1)
//            if indexBuffer.count > 0 {
//                for i in indexBuffer {
//                    encoder.drawIndexedPrimitives(type: i.primitiveType,
//                                                  indexCount: i.indexCount,
//                                                  indexType: i.indexType,
//                                                  indexBuffer: i.indexBuffer,
//                                                  indexBufferOffset: i.indexBufferOffset)
//                }
//            }else{
//                encoder.drawPrimitives(type: primitiveType,
//                                       vertexStart: 0,
//                                       vertexCount: vertexCount)
//            }
//        }
//        
//        public static func plant(render:Render,shader:Shader)throws ->Model<ModelObject>{
//            var m = Model<ModelObject>(vertexShader: "vertexPlainRender", fragmentShader: "fragmentPlainRender")
//            let vertex:[Float] = [
//                 -1, 0, 1,        0,0, 0,1,0,
//                  1, 0, 1,        1,0, 0,1,0,
//                 -1, 0, -1,       0,1, 0,1,0,
//                  
//                  1, 0, -1,       1,1, 0,1,0,
//            ]
//            m.diffuse = render.checkerboard;
//            m.model.pointee.model = simd_float4x4.identity
//            m.ambient = render.checkerboardCube;
//            m.diffuse = render.checkerboard;
//            m.specular = render.checkerboard;
//            m.vertexBuffer = render.device.makeBuffer(bytes: vertex, length: MemoryLayout<Float>.size * vertex.count)
//            m.vertexCount = 4
//            m.cullMode = .front
//            m.primitiveType = .triangleStrip
//            m.vertexDesciption = MTLVertexDescriptor()
//            m.vertexDesciption?.layouts[0].stride = 8 * MemoryLayout<Float>.size
//            m.vertexDesciption?.attributes[0].bufferIndex = Int(model_vertex_buffer_index)
//            m.vertexDesciption?.attributes[0].format = .float3
//            m.vertexDesciption?.attributes[0].offset = 0
//            m.vertexDesciption?.attributes[1].bufferIndex = Int(model_vertex_buffer_index)
//            m.vertexDesciption?.attributes[1].format = .float2
//            m.vertexDesciption?.attributes[1].offset = 3 * MemoryLayout<Float>.size
//            m.vertexDesciption?.attributes[2].bufferIndex = Int(model_vertex_buffer_index)
//            m.vertexDesciption?.attributes[2].format = .float3
//            m.vertexDesciption?.attributes[2].offset = 5 * MemoryLayout<Float>.size
//
//            try render.createRenderDisplayPiplineState(shader: shader, model: &m)
//            return m
//        }
//        
//        public static func ball(size:vector_float3, render:Render,shader:Shader)throws ->Model<ModelObject>{
//            var m = Model<ModelObject>(vertexShader: "vertexPlainRender", fragmentShader: "fragmentPlainRender")
//            
//            m.diffuse = render.checkerboard;
//            m.model.pointee.model = simd_float4x4.identity
//            m.ambient = render.checkerboardCube;
//            m.diffuse = render.checkerboard;
//            m.specular = render.checkerboard;
//            
//            m.cullMode = .front
//            let md = MDLMesh(sphereWithExtent: size, segments: [10,10], inwardNormals: false, geometryType: .triangles, allocator:  MTKMeshBufferAllocator(device: render.device))
//            let mk = try! MTKMesh(mesh: md, device: render.device)
//            m.loadMesh(mesh: mk)
//    
//            try render.createRenderDisplayPiplineState(shader: shader, model: &m)
//            return m
//        }
//        
//        public static func skybox(render:Render,shader:Shader)throws ->Model<ModelObject>{
//            var m = Model<ModelObject>(vertexShader: "vertexSkyboxRender", fragmentShader: "fragmentSkyboxRender")
//            
//            let md = MDLMesh(sphereWithExtent: [30,30,30], segments: [30,30], inwardNormals: false, geometryType: .triangles, allocator:  MTKMeshBufferAllocator(device: render.device))
//            let mk = try! MTKMesh(mesh: md, device: render.device)
//            m.loadMesh(mesh: mk)
//            
//            m.model.pointee.model = simd_float4x4.scale(m: simd_float4x4.identity, v: [15,15,15])
//            m.ambient = render.checkerboardCube;
//            m.cullMode = .back
//            try render.createRenderDisplayPiplineState(shader: shader, model: &m)
//            return m
//        }
//    }
//    
//    
//}
//
//extension MR.Model where T == ModelObject{
//    public func calcNormalMatrix(){
//        self.model.pointee.normal_model = simd_float4x4.normalMatrix(m: model.pointee.model)
//    }
//}
