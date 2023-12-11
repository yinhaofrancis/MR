//
//  MShader.swift
//  MR
//
//  Created by wenyang on 2023/12/11.
//

import Metal
import MetalKit
import simd
import Foundation


extension AL{
    public struct Shader{
        
        public static let shared:Shader = try! Shader(render: Render.shared)
        
        public let lib:MTLLibrary
        
        public let render:Render
        
        public init(render:Render,url:URL) throws {
            self.render = render
            
            self.lib = try render.device.makeLibrary(URL: url)
        }
        
        public init(render:Render,bundle:Bundle = CurrentBundle) throws {
            self.render = render
            
            self.lib = try render.device.makeDefaultLibrary(bundle: bundle)
        }
    }
}

extension AL.Shader{
    public func createRenderDisplayPiplineState<T:Renderable>(model:inout T)throws{
        
        let desc = MTLRenderPipelineDescriptor()
        desc.colorAttachments[0].pixelFormat = ColorPixel;
        desc.colorAttachments[0].isBlendingEnabled = true;
        desc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusBlendAlpha
        desc.depthAttachmentPixelFormat = DepthStencilPixel
        desc.stencilAttachmentPixelFormat = DepthStencilPixel
        desc.vertexFunction = self.lib.makeFunction(name: model.vertexShader)
        desc.fragmentFunction = self.lib.makeFunction(name: model.fragmentShader)
        desc.vertexDescriptor = model.vertexDesciption
        let state = try self.render.device.makeRenderPipelineState(descriptor: desc)
        model.renderPiplineState = state
        
        if let dep = model.depthStencilDescriotion{
            model.depthStencilState = self.render.device.makeDepthStencilState(descriptor: dep)
        }else{
            model.depthStencilState = self.render.defaultDepthState
        }
    }
    public func createCopyScreenPiplineState() throws ->MTLRenderPipelineState{
        let desc = MTLRenderPipelineDescriptor()
        desc.colorAttachments[0].pixelFormat = ColorPixel;
        desc.vertexFunction = self.lib.makeFunction(name: "VertexScreenDisplayRender")
        desc.fragmentFunction = self.lib.makeFunction(name: "FragmentScreenDisplayRender")
        return try self.render.device.makeRenderPipelineState(descriptor: desc)
    }
}
