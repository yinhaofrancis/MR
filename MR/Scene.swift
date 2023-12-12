////
////  Scene.swift
////  MR
////
////  Created by wenyang on 2023/12/9.
////
//
//import Metal
//import MetalKit
//import simd
//import Foundation
//
//public protocol Scene{
//    associatedtype S
//    var scene:UnsafeMutablePointer<S> { get }
//    func load(encoder:MTLRenderCommandEncoder?)
//}
//extension MR{
//    public class DisplayScene<T>:Scene{
//    
//        
//        
//        public init(){}
//        
//        public var scene: UnsafeMutablePointer<T> = .allocate(capacity: 1)
//        
//        public typealias S = T
//        
//        public func load(encoder: MTLRenderCommandEncoder?) {
//            encoder?.setVertexBytes(scene, length: MemoryLayout<T>.size, index: Int(camera_object_buffer_index))
//            encoder?.setFragmentBytes(scene, length: MemoryLayout<T>.size, index: Int(camera_object_buffer_index))
//        }
//        
//        deinit{
//            scene.deallocate()
//        }
//    }
//}
//
//extension MR.DisplayScene where T == CameraObject{
//    public func lookat(eye: simd_float3, center: simd_float3) {
//        self.scene.pointee.view = float4x4.lookat(eye: eye, center: center, up: [0,1,0])
//        self.scene.pointee.camera_pos = eye;
//    }
//}
