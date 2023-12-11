//
//  RenderPass.swift
//  MR
//
//  Created by wenyang on 2023/12/10.
//

import Metal
import MetalKit
import simd
import Foundation


extension AL{
    public class RenderPass{
        public let renderPass:MTLRenderPassDescriptor
        public let render:AL.Render
        public var depthStencilTexture:AL.Texture?{
            didSet{
                self.renderPass.depthAttachment.texture = depthStencilTexture?.texture
                self.renderPass.stencilAttachment.texture = depthStencilTexture?.texture
            }
        }
        public var colorTexture:MTLTexture?{
            didSet{
                self.renderPass.colorAttachments[0].texture = colorTexture
            }
        }
        
        public var width:Int{
            Int(colorTexture?.width ?? 0)
        }
        public var height:Int{
            Int(colorTexture?.height ?? 0)
        }
        public var layer:CAMetalLayer?
        public private(set) var drawable:MTLDrawable?
        
        public static let shared:AL.RenderPass = AL.RenderPass(render: .shared)
        
        public func configScene() {
            self.renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0,0,0,1);
            self.renderPass.colorAttachments[0].loadAction = .clear
            self.renderPass.colorAttachments[0].storeAction = .store
            self.renderPass.depthAttachment.clearDepth = 1
            self.renderPass.depthAttachment.loadAction = .clear
            self.renderPass.depthAttachment.storeAction = .store
            self.renderPass.stencilAttachment.clearStencil = 1;
            self.renderPass.stencilAttachment.loadAction = .clear
            self.renderPass.stencilAttachment.storeAction = .store
        }
        
        public init(render:AL.Render) {
            self.render = render
            self.renderPass = MTLRenderPassDescriptor();
            configScene()
        }
        public func beginRender(buffer:MTLCommandBuffer,layer:CAMetalLayer)->MTLRenderCommandEncoder?{
            layer.device = render.device
            layer.maximumDrawableCount = 3;
            layer.pixelFormat = ColorPixel
            layer.drawableSize = layer.bounds.size
            guard let mtlDrawable = layer.nextDrawable() else { return nil }
            self.drawable = mtlDrawable
            self.colorTexture = mtlDrawable.texture
            if(depthStencilTexture == nil){
                depthStencilTexture = render.newDepthStencilTexture(width: mtlDrawable.texture.width, height: mtlDrawable.texture.height)
            }
            if layer.drawableSize.width > 0 && layer.drawableSize.height > 0{
                return buffer.makeRenderCommandEncoder(descriptor: self.renderPass)
            }
            return nil
        }
        public func beginTextureRender(buffer:MTLCommandBuffer,texture:MTLTexture)->MTLRenderCommandEncoder?{
        
            self.colorTexture = texture
            if(depthStencilTexture == nil){
                depthStencilTexture = render.newDepthStencilTexture(width: texture.width, height: texture.height)
            }
            else{
                self.renderPass.depthAttachment.texture = depthStencilTexture?.texture
                self.renderPass.stencilAttachment.texture = depthStencilTexture?.texture
            }
            return buffer.makeRenderCommandEncoder(descriptor: self.renderPass)
        }
        public func beginColorRender(buffer:MTLCommandBuffer,layer:CAMetalLayer)->MTLRenderCommandEncoder?{
            layer.device = render.device
            layer.maximumDrawableCount = 3;
            layer.pixelFormat = ColorPixel
            layer.drawableSize = layer.bounds.size
            guard let mtlDrawable = layer.nextDrawable() else { return nil }
            self.drawable = mtlDrawable
            self.colorTexture = mtlDrawable.texture
            self.renderPass.depthAttachment.texture = nil
            self.renderPass.stencilAttachment.texture = nil
            self.renderPass.colorAttachments[0].resolveTexture = nil
            return buffer.makeRenderCommandEncoder(descriptor: self.renderPass)
        }
        public func setViewPort(encoder:MTLRenderCommandEncoder?){
            encoder?.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(self.width), height: Double(self.height), znear: 0, zfar: 1))
        }
    }
}
