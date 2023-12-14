//
//  Material.swift
//  TFRender
//
//  Created by wenyang on 2023/12/13.
//

import Metal
import MetalKit
import simd
import Foundation

extension Renderer.Texture{
    
    
    public static func randomBuffer(size:Int)->[UInt8]{
        var buf:[UInt8] = []
        for _ in (0 ..< (size * size)) {
            buf.append(UInt8.random(in: 0 ..< 255))
        }
        return buf
    }
    
    public static var defaultTexture:Renderer.Texture = {
        let size = Int.random(in: 2 ..< 100)
        
        var v = try! Renderer.Texture(width: size, height: size, pixel: .r8Unorm,colorSwizzle: .red)
        v.sampler = .defaultNesrestSampler
        let value:[UInt8] = randomBuffer(size: size)
        v.assign(width: size, height: size, bytesPerRow: size, withBytes: value)
        return v
    }()
    
    public static var defaultTextureCube:Renderer.Texture = {
        let size = Int.random(in: 2 ..< 200)
        var v = try! Renderer.Texture(width: size, height: size, pixel: .r8Unorm,type: .typeCube,colorSwizzle: .red)
        v.sampler = .defaultNesrestSampler
        let value:[UInt8] = randomBuffer(size: size)
        for i in 0 ..< 6{
            v.assign(region: MTLRegion(origin: .init(x: 0, y: 0, z: 0), size: .init(width: size, height: size, depth: 1)), level: 0, slice: i, bytes: value, bytesPerRow: size, bytePerImage: size * size)
        }
        
        return v
    }()
    
    public static var defaultSpecular:Renderer.Texture = {
        var v = try! Renderer.Texture(width: 2, height: 2, pixel: .r8Unorm,colorSwizzle: .red)
        v.sampler = .defaultNesrestSampler
        let value:[UInt8] = [
           20,20,20,20
        ]
        v.assign(width: 2, height: 2, bytesPerRow: 2, withBytes: value)
        return v
    }()
    public static var defaultAmbient:Renderer.Texture = {
        var v = try! Renderer.Texture(width: 2, height: 2, pixel: .r8Unorm,colorSwizzle: .red)
        v.sampler = .defaultNesrestSampler
        let value:[UInt8] = [
           100,100,100,100
        ]
        v.assign(width: 2, height: 2, bytesPerRow: 2, withBytes: value)
        return v
    }()
    public static var defaultNormal:Renderer.Texture = {
        var v = try! Renderer.Texture(width: 2, height: 2, pixel:.rgba32Float)
        v.sampler = .defaultNesrestSampler
        let value:[Float] = [
            0.5,0.5,1,1,
            0.5,0.5,1,1,
            0.5,0.5,1,1,
            0.5,0.5,1,1
        ]
        v.assign(width: 2, height: 2, bytesPerRow: 2 * 4 * 4, withBytes: value)
        return v
    }()
}

public class Material{
    public var diffuse:Renderer.Texture? = .defaultTexture
    public var specular:Renderer.Texture? = .defaultSpecular
    public var normal:Renderer.Texture? = .defaultNormal
    public var ambient:Renderer.Texture? = .defaultTextureCube
    public init() {}
}

public class Shadow{
    public var globelShadow:MTLTexture?
    public init() {}
}
