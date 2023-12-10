//
//  TextureLoader.swift
//  MR
//
//  Created by wenyang on 2023/12/9.
//

import Foundation
import Metal
import MetalKit

public struct TextureLoader{

    public static let shared:TextureLoader = TextureLoader(render: AL.Render.shared)
    
    public let textureLoader:MTKTextureLoader
    public let render:AL.Render
    public init(render:AL.Render){
        self.render = render
        textureLoader = MTKTextureLoader(device: render.device)
    }
    
    public func texture(name:String,callback:@escaping (AL.Texture?)->Void){
        textureLoader.newTexture(name: name, scaleFactor: 1, bundle: nil) { texture, e in
            if e == nil {
                callback(AL.Texture(texture: texture!, samplerState: render.defaultSampler))
            }
        }
    }
}
