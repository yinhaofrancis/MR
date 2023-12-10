////
////  Texture.swift
////  MR
////
////  Created by wenyang on 2023/12/8.
////
//
//import Metal
//import MetalKit
//
//import simd
//import Foundation
//
//
//extension MR.Render{
//    public func newColorTexture(width:Int,
//                                height:Int,
//                                usage:MTLTextureUsage,
//                                storageMode: MTLStorageMode)->Texture?{
//        let desc = MTLTextureDescriptor()
//        desc.width = width;
//        desc.height = height;
//        desc.textureType = .type2D
//        desc.pixelFormat = ColorPixel
//        desc.usage = usage
//        desc.storageMode = storageMode
//        guard let d = device.makeTexture(descriptor: desc) else { return nil }
//        return Texture(texture: d, samplerState: self.defaultSampler)
//    }
//    public func newStencilTexture(width:Int,height:Int)->Texture?{
//        let desc = MTLTextureDescriptor()
//        desc.width = width;
//        desc.textureType = .type2D
//        desc.height = height;
//        desc.pixelFormat = StencilPixel
//        desc.usage = .renderTarget
//        desc.storageMode = .private
//        guard let d = device.makeTexture(descriptor: desc) else { return nil }
//        return Texture(texture: d, samplerState: self.defaultSampler)
//    }
//    public func newDepthStencilTexture(width:Int,height:Int)->Texture?{
//        let desc = MTLTextureDescriptor()
//        desc.width = width;
//        desc.textureType = .type2D
//        desc.height = height;
//        desc.pixelFormat = DepthStencilPixel
//        desc.usage = .renderTarget
//        desc.storageMode = .private
//        guard let d = device.makeTexture(descriptor: desc) else { return nil }
//        return Texture(texture: d, samplerState: self.defaultSampler)
//    }
//    public func newDepthTexture(width:Int,height:Int)->Texture?{
//        let desc = MTLTextureDescriptor()
//        desc.width = width;
//        desc.textureType = .type2D
//        desc.height = height;
//        desc.pixelFormat = DepthPixel
//        desc.usage = .renderTarget
//        desc.storageMode = .private
//        guard let d = device.makeTexture(descriptor: desc) else { return nil }
//        return Texture(texture: d, samplerState: self.defaultSampler)
//    }
//    
//    public func newTexture(width:Int,
//                           height:Int,
//                           bytesPerRow:Int,
//                           pixelFormat:MTLPixelFormat,
//                           value:[UInt8])->Texture?{
//        let desc = MTLTextureDescriptor()
//        desc.width = width;
//        desc.height = height;
//        desc.textureType = .type2D
//        desc.pixelFormat = pixelFormat
//        desc.usage = .shaderRead
//        desc.storageMode = .shared
//        guard let d = device.makeTexture(descriptor: desc) else { return nil }
//        let r = Texture(texture: d, samplerState: self.defaultSampler)
//        r.loadData(value: value, region: MTLRegionMake2D(0, 0, width, height), bytesPerRow: bytesPerRow)
//        return r
//    }
//    
//    public struct Texture{
//        public enum CubeIndex:IntegerLiteralType{
//
//            case PositiveX = 0
//            case NegtiveX = 1
//            case PositiveY = 2
//            case NegtiveY = 3
//            case PositiveZ = 4
//            case NegtiveZ = 5
//        }
//        public var texture:MTLTexture
//        public var samplerState:MTLSamplerState
//        public init(texture: MTLTexture,samplerState:MTLSamplerState) {
//            self.texture = texture
//            self.samplerState = samplerState
//        }
//        public func loadData(value:[UInt8],region:MTLRegion,bytesPerRow:Int){
//            self.texture.replace(region: region, mipmapLevel: 0, withBytes: value, bytesPerRow: bytesPerRow)
//        }
//        
//        public func loadCubeData(value:[UInt8],index:CubeIndex,region:MTLRegion,bytesPerRow:Int,bytePerImage:Int){
//            self.texture.replace(region: region, mipmapLevel: 0, slice: index.rawValue, withBytes: value, bytesPerRow: bytesPerRow, bytesPerImage: bytePerImage)
//        }
//    }
//}
//
