//
//  MTexture.swift
//  MR
//
//  Created by wenyang on 2023/12/10.
//

import Metal
import MetalKit
import simd
import Foundation


extension AL{
    public class Texture{
        public enum CubeIndex:IntegerLiteralType{

            case PositiveX = 0
            case NegtiveX = 1
            case PositiveY = 2
            case NegtiveY = 3
            case PositiveZ = 4
            case NegtiveZ = 5
        }
        public var texture:MTLTexture
        
        public var samplerState:MTLSamplerState
        
        public init(texture: MTLTexture,samplerState:MTLSamplerState) {
            self.texture = texture
            self.samplerState = samplerState
        }
        public func loadData(byte:UnsafeRawPointer,region:MTLRegion,bytesPerRow:Int){
            self.texture.replace(region: region, mipmapLevel: 0, withBytes: byte, bytesPerRow: bytesPerRow)
        }
        
        public func loadData(byte:UnsafeRawPointer,index:Int,region:MTLRegion,bytesPerRow:Int,bytePerImage:Int){
            self.texture.replace(region: region, mipmapLevel: 0, slice: index, withBytes: byte, bytesPerRow: bytesPerRow, bytesPerImage: bytePerImage)
        }

    }
}

extension AL.Render {
    public func newColorTexture(width:Int,
                                height:Int,
                                usage:MTLTextureUsage,
                                storageMode: MTLStorageMode)->AL.Texture?{
        let desc = MTLTextureDescriptor()
        desc.width = width;
        desc.height = height;
        desc.textureType = .type2D
        desc.pixelFormat = ColorPixel
        desc.usage = usage
        desc.storageMode = storageMode
        guard let d = device.makeTexture(descriptor: desc) else { return nil }
        return AL.Texture(texture: d, samplerState: self.defaultSampler)
    }
    public func newStencilTexture(width:Int,height:Int)->AL.Texture?{
        let desc = MTLTextureDescriptor()
        desc.width = width;
        desc.textureType = .type2D
        desc.height = height;
        desc.pixelFormat = StencilPixel
        desc.usage = .renderTarget
        desc.storageMode = .private
        guard let d = device.makeTexture(descriptor: desc) else { return nil }
        return AL.Texture(texture: d, samplerState: self.defaultSampler)
    }
    public func newDepthStencilTexture(width:Int,height:Int)->AL.Texture?{
        let desc = MTLTextureDescriptor()
        desc.width = width;
        desc.textureType = .type2D
        desc.height = height;
        desc.pixelFormat = DepthStencilPixel
        desc.usage = .renderTarget
        desc.storageMode = .private
        guard let d = device.makeTexture(descriptor: desc) else { return nil }
        return AL.Texture(texture: d, samplerState: self.defaultSampler)
    }
    public func newDepthTexture(width:Int,height:Int)->AL.Texture?{
        let desc = MTLTextureDescriptor()
        desc.width = width;
        desc.textureType = .type2D
        desc.height = height;
        desc.pixelFormat = DepthPixel
        desc.usage = .renderTarget
        desc.storageMode = .private
        guard let d = device.makeTexture(descriptor: desc) else { return nil }
        return AL.Texture(texture: d, samplerState: self.defaultSampler)
    }
    
    public func newTexture(width:Int,
                           height:Int,
                           bytesPerRow:Int,
                           pixelFormat:MTLPixelFormat,
                           value:UnsafeRawPointer)->AL.Texture?{
        let desc = MTLTextureDescriptor()
        desc.width = width;
        desc.height = height;
        desc.textureType = .type2D
        desc.pixelFormat = pixelFormat
        desc.usage = .shaderRead
        desc.storageMode = .shared
        guard let d = device.makeTexture(descriptor: desc) else { return nil }
        let r = AL.Texture(texture: d, samplerState: self.defaultSampler)
        r.loadData(byte: value, region: MTLRegionMake2D(0, 0, width, height), bytesPerRow: bytesPerRow)
        return r
    }
}
