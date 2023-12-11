//
//  MRender.swift
//  MR
//
//  Created by wenyang on 2023/12/10.
//

import Metal
import MetalKit
import simd
import Foundation


public enum AL{
    public class Render{
        
        public init() throws{
            guard let de = MTLCreateSystemDefaultDevice() else {
                throw NSError(domain: "create device fail", code: 0)
            }
            device = de
        }
        
        public let device:MTLDevice
        
        public func createQueue() throws ->Queue{
            return try Queue(render: self)
        }
        
        public static let shared:Render = try! Render()
        
        
        public private (set) lazy var defaultSampler:MTLSamplerState = {
            let sampler = MTLSamplerDescriptor()
            sampler.magFilter = .linear
            sampler.minFilter = .linear
            sampler.mipFilter = .notMipmapped
            sampler.sAddressMode = .repeat
            sampler.tAddressMode = .repeat
            sampler.rAddressMode = .repeat
            return self.device.makeSamplerState(descriptor: sampler)!
        }()
        public private (set) lazy var defaultNearestSampler:MTLSamplerState  = {
            let sampler = MTLSamplerDescriptor()
            sampler.magFilter = .nearest
            sampler.minFilter = .nearest
            sampler.sAddressMode = .repeat
            sampler.tAddressMode = .repeat
            sampler.rAddressMode = .repeat
            sampler.mipFilter = .notMipmapped
            return self.device.makeSamplerState(descriptor: sampler)!
        }()
        
        
        public private (set) lazy var checkerboard:AL.Texture? = {
            let desc = MTLTextureDescriptor()
            desc.width = 2;
            desc.height = 2;
            desc.textureType = .type2D
            desc.pixelFormat = .r8Unorm
            desc.swizzle = .init(red: .red, green: .red, blue: .red, alpha: .red)
            desc.usage = .shaderRead
            desc.storageMode = .shared
            guard let d = self.device.makeTexture(descriptor: desc) else { return nil }
            let r = AL.Texture(texture: d, samplerState: self.defaultNearestSampler)
            let value:[UInt8] = [
                255,1,1,255
            ]
            r.loadData(byte: value, region: MTLRegionMake2D(0, 0, 2, 2), bytesPerRow: 2)
            return r
        }()
        
        public private (set) lazy var gray:AL.Texture? = {
            let desc = MTLTextureDescriptor()
            desc.width = 2;
            desc.height = 2;
            desc.textureType = .type2D
            desc.pixelFormat = .r8Unorm
            desc.swizzle = .init(red: .red, green: .red, blue: .red, alpha: .red)
            desc.usage = .shaderRead
            desc.storageMode = .shared
            guard let d = self.device.makeTexture(descriptor: desc) else { return nil }
            let r = AL.Texture(texture: d, samplerState: self.defaultNearestSampler)
            let value:[UInt8] = [
                75,75,75,75
            ]
            r.loadData(byte: value, region: MTLRegionMake2D(0, 0, 2, 2), bytesPerRow: 2)
            return r
        }()
        
        public private (set) lazy var defaultAmbient:AL.Texture? = {
            let desc = MTLTextureDescriptor()
            desc.width = 2;
            desc.height = 2;
            desc.textureType = .typeCube
            desc.pixelFormat = .r8Unorm
            desc.swizzle = .init(red: .red, green: .red, blue: .red, alpha: .red)
            desc.usage = .shaderRead
            desc.storageMode = .shared
            guard let d = self.device.makeTexture(descriptor: desc) else { return nil }
            let r = AL.Texture(texture: d, samplerState: self.defaultNearestSampler)
            let value:[UInt8] = [
                64,64,64,64
            ]
            for i in 0 ..< 6{
                r.loadData(byte: value, index: i, region: MTLRegionMake2D(0, 0, 2, 2), bytesPerRow: 2, bytePerImage: 4)
            }
            return r
        }()
        public private (set) lazy var black:AL.Texture? = {
            let desc = MTLTextureDescriptor()
            desc.width = 2;
            desc.height = 2;
            desc.textureType = .type2D
            desc.pixelFormat = .r8Unorm
            desc.swizzle = .init(red: .red, green: .red, blue: .red, alpha: .red)
            desc.usage = .shaderRead
            desc.storageMode = .shared
            guard let d = self.device.makeTexture(descriptor: desc) else { return nil }
            let r = AL.Texture(texture: d, samplerState: self.defaultNearestSampler)
            let value:[UInt8] = [
                8,8,8,8
            ]
            r.loadData(byte: value, region: MTLRegionMake2D(0, 0, 2, 2), bytesPerRow: 2)
            return r
        }()
        
        public private (set) lazy var defaultSpeclar:AL.Texture? = {
            self.gray
        }()
        
        public func randomNormalTexture(width:Int,height:Int)->AL.Texture?{
            let desc = MTLTextureDescriptor()
            let com = 4
            desc.width = width;
            desc.height = height;
            desc.textureType = .type2D
            desc.pixelFormat = ColorPixel

            desc.usage = .shaderRead
            desc.storageMode = .shared
            guard let d = self.device.makeTexture(descriptor: desc) else { return nil }

            let r:AL.Texture? = AL.Texture(texture: d, samplerState: self.defaultSampler)
            let value:[UInt8] = Render.randomNormal(width: 200, height: 200)
            r?.loadData(byte: value, region: MTLRegionMake2D(0,0, width, height), bytesPerRow: width * com)
            return r
        }
        public private (set) lazy var defaultNormal:AL.Texture? = {
            let desc = MTLTextureDescriptor()
     
            desc.width = 2;
            desc.height = 2;
            desc.textureType = .type2D
            desc.pixelFormat = ColorPixel

            desc.usage = .shaderRead
            desc.storageMode = .shared
            guard let d = self.device.makeTexture(descriptor: desc) else { return nil }

            let r:AL.Texture? = AL.Texture(texture: d, samplerState: self.defaultNearestSampler)
            let value:[UInt8] = [
                255,127,127,255,
                255,127,127,255,
                255,127,127,255,
                255,127,127,255,
            ]
            r?.loadData(byte: value, region: MTLRegionMake2D(0,0, 2, 2), bytesPerRow:8)
            return r
        }()
        public static func randomNormal(width:Int,height:Int)->[UInt8]{
        
            var result:[UInt8] = []
            for i in 0 ..< height{
                for j in 0 ..< width{
                    let x = 0.05 + 0.05 * sin(2.0 * Float(j))
                    let y = 0.05 + 0.05 * sin(2.0 * Float(i))
                    
                    let a = normalToColorComponent(normal: [x,y,1])
                    result.append(a.0)
                    result.append(a.1)
                    result.append(a.2)
                    result.append(255)
                }
            }
            return result
        }
    
        public static func normalToColorComponent(normal:simd_float3)->(UInt8,UInt8,UInt8){
            let v = (normal / 2 + 0.5) * 255
            return (UInt8(v.x),UInt8(v.y),UInt8(v.z))
        }
        public private (set) lazy var checkerboardCube:AL.Texture? = {
            let desc = MTLTextureDescriptor()
            desc.width = 2;
            desc.height = 2;
            desc.textureType = .typeCube
            desc.pixelFormat = .r8Unorm
            desc.swizzle = .init(red: .red, green: .red, blue: .red, alpha: .red)
            desc.usage = .shaderRead
            desc.storageMode = .shared
            guard let d = self.device.makeTexture(descriptor: desc) else { return nil }
            let r = AL.Texture(texture: d, samplerState: self.defaultNearestSampler)
            let value:[UInt8] = [
                255,1,1,255
            ]

            for i in 0 ..< 6 {
                r.loadData(byte: value, index: i, region: MTLRegionMake2D(0, 0, 2, 2), bytesPerRow: 2, bytePerImage: 4)
            }
            return r
        }()
        public private(set) lazy var defaultDepthState:MTLDepthStencilState = {
            let d = MTLDepthStencilDescriptor()
            d.depthCompareFunction = .less
            d.isDepthWriteEnabled = true
            return self.device.makeDepthStencilState(descriptor: d)!
        }()
    }
    
    public struct Queue{
        
        public static let shared:Queue = try! Queue(render: Render.shared)
        
        public private(set) var render:Render
                
        public let renderQueue:MTLCommandQueue
        
        public init(render:Render) throws {
            self.render = render
            guard let q = render.device.makeCommandQueue() else { throw NSError(domain: "create render queue fail", code: 1)  }
            self.renderQueue = q
        }
        public func createBuffer()->MTLCommandBuffer?{
            return autoreleasepool {
                self.renderQueue.makeCommandBuffer()
            }
            
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
