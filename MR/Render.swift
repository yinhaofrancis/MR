////
////  Render.swift
////  mmmm
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
//
//public struct MR{
//    
//    public static let sharedRender:Render = try! Render()
//    
//    public static let sharedQueue:Queue = try! Queue(render: sharedRender)
//    
//    public static let sharedShader:Shader = try! Shader(render: sharedRender)
//    
//    
//    
//    public class Render{
//        public init() throws{
//            guard let de = MTLCreateSystemDefaultDevice() else {
//                throw NSError(domain: "create device fail", code: 0)
//            }
//            device = de
//        }
//        
//        public let device:MTLDevice
//        
//        public func createQueue() throws ->Queue{
//            return try Queue(render: self)
//        }
//        public func createRenderDisplayPiplineState<T:Renderable>(shader:Shader,model:inout T)throws{
//            
//            let desc = MTLRenderPipelineDescriptor()
//            desc.colorAttachments[0].pixelFormat = ColorPixel;
//            desc.colorAttachments[0].isBlendingEnabled = true;
//            desc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
//            desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusBlendAlpha
//            desc.depthAttachmentPixelFormat = DepthStencilPixel
//            desc.stencilAttachmentPixelFormat = DepthStencilPixel
//            desc.vertexFunction = shader.lib.makeFunction(name: model.vertexShader)
//            desc.fragmentFunction = shader.lib.makeFunction(name: model.fragmentShader)
//            desc.vertexDescriptor = model.vertexDesciption
//            
//            let state = try device.makeRenderPipelineState(descriptor: desc)
//            model.renderPiplineState = state
//            
//            if let dep = model.depthStencilDescriotion{
//                model.depthStencilState = device.makeDepthStencilState(descriptor: dep)
//            }else{
//                model.depthStencilState = defaultDepthState
//            }
//        }
//        public private(set) lazy var defaultDepthState:MTLDepthStencilState = {
//            let d = MTLDepthStencilDescriptor()
//            d.depthCompareFunction = .less
//            d.isDepthWriteEnabled = true
//            return self.device.makeDepthStencilState(descriptor: d)!
//        }()
//        
//        public private(set) lazy var defaultSampler:MTLSamplerState = {
//            let sampler = MTLSamplerDescriptor()
//            sampler.magFilter = .linear
//            sampler.minFilter = .linear
//            sampler.mipFilter = .notMipmapped
//            sampler.sAddressMode = .repeat
//            sampler.tAddressMode = .repeat
//            sampler.rAddressMode = .repeat
//            return device.makeSamplerState(descriptor: sampler)!
//        }()
//        public private(set) lazy var defaultNearestSampler:MTLSamplerState = {
//            let sampler = MTLSamplerDescriptor()
//            sampler.magFilter = .nearest
//            sampler.minFilter = .nearest
//            sampler.sAddressMode = .repeat
//            sampler.tAddressMode = .repeat
//            sampler.rAddressMode = .repeat
//            sampler.mipFilter = .notMipmapped
//            return device.makeSamplerState(descriptor: sampler)!
//        }()
//        
//        public private(set) lazy var checkerboard:Texture? = {
//            let desc = MTLTextureDescriptor()
//            desc.width = 2;
//            desc.height = 2;
//            desc.textureType = .type2D
//            desc.pixelFormat = .r8Unorm
//            desc.swizzle = .init(red: .red, green: .red, blue: .red, alpha: .red)
//            desc.usage = .shaderRead
//            desc.storageMode = .shared
//            guard let d = device.makeTexture(descriptor: desc) else { return nil }
//            let r = Texture(texture: d, samplerState: self.defaultSampler
//            )
//            let value:[UInt8] = [
//                255,0,0,255
//            ]
//            r.loadData(value: value, region: MTLRegionMake2D(0, 0, 2, 2), bytesPerRow: 2)
//            return r
//        }()
//        
//        public private(set) lazy var checkerboardCube:Texture? = {
//            let desc = MTLTextureDescriptor()
//            desc.width = 2;
//            desc.height = 2;
//            desc.textureType = .typeCube
//            desc.pixelFormat = .r8Unorm
//            desc.swizzle = .init(red: .red, green: .red, blue: .red, alpha: .red)
//            desc.usage = .shaderRead
//            desc.storageMode = .shared
//            guard let d = device.makeTexture(descriptor: desc) else { return nil }
//            let r = Texture(texture: d, samplerState: self.defaultSampler)
//            let value:[UInt8] = [
//                255,0,0,255
//            ]
//
//            for i in 0 ..< 6 {
//                r.loadCubeData(value: value, index: MR.Render.Texture.CubeIndex(rawValue: i)!, region:MTLRegionMake2D(0, 0, 2, 2), bytesPerRow: 2, bytePerImage: 4)
//            }
//            return r
//        }()
//    }
//    
//    
//    public struct Shader{
//        public let lib:MTLLibrary
//        public let render:Render
//        public init(render:Render,url:URL) throws {
//            self.render = render
//            
//            self.lib = try render.device.makeLibrary(URL: url)
//        }
//        public init(render:Render,bundle:Bundle = CurrentBundle) throws {
//            self.render = render
//            
//            self.lib = try render.device.makeDefaultLibrary(bundle: bundle)
//        }
//    }
//   
//   
//    
//    public struct Queue{
//        
//        public let render:Render
//                
//        public let renderQueue:MTLCommandQueue
//        
//        public init(render:Render) throws {
//            self.render = render
//            guard let q = render.device.makeCommandQueue() else { throw NSError(domain: "create render queue fail", code: 1)  }
//            self.renderQueue = q
//        }
//        public func createBuffer()->MTLCommandBuffer?{
//            return autoreleasepool {
//                self.renderQueue.makeCommandBuffer()
//            }
//            
//        }
//    }
//    
//    public class RenderDisplay{
//        public let renderPass:MTLRenderPassDescriptor
//        public let layer:CAMetalLayer
//        public let render:Render
//        public var depthStencilTexture:MR.Render.Texture?
//        public var width:Int{
//            Int(layer.drawableSize.width)
//        }
//        public var height:Int{
//            Int(layer.drawableSize.height)
//        }
//        public private(set) var drawable:MTLDrawable?
//        public init(render:Render) {
//            self.render = render
//            self.layer = CAMetalLayer()
//            self.layer.device = render.device
//            self.layer.maximumDrawableCount = 3;
//            self.layer.pixelFormat = ColorPixel
//            self.renderPass = MTLRenderPassDescriptor();
//            self.renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0,0,0,0);
//            self.renderPass.colorAttachments[0].loadAction = .clear
//            self.renderPass.colorAttachments[0].storeAction = .store
//            self.renderPass.depthAttachment.clearDepth = 1
//            self.renderPass.depthAttachment.loadAction = .clear
//            self.renderPass.depthAttachment.storeAction = .store
//            self.renderPass.stencilAttachment.clearStencil = 1;
//            self.renderPass.stencilAttachment.loadAction = .clear
//            self.renderPass.stencilAttachment.storeAction = .store
//        }
//        public func next(){
//
//            guard let drawable =  autoreleasepool(invoking: {layer.nextDrawable()}) else {
//                print("drawable is null")
//                return
//            }
//            self.drawable = drawable
//            if(depthStencilTexture == nil){
//                depthStencilTexture = render.newDepthStencilTexture(width: drawable.texture.width, height: drawable.texture.height)
//            }
//
//            self.renderPass.colorAttachments[0].texture = drawable.texture
//            self.renderPass.depthAttachment.texture = depthStencilTexture?.texture
//            self.renderPass.stencilAttachment.texture = depthStencilTexture?.texture
//        }
//        public func reset(){
//            self.depthStencilTexture = nil
//        }
//        public func beginRender(buffer:MTLCommandBuffer)->MTLRenderCommandEncoder?{
//            layer.drawableSize = layer.bounds.size
//            if layer.drawableSize.width > 0 && layer.drawableSize.height > 0{
//                self.next()
//                return buffer.makeRenderCommandEncoder(descriptor: self.renderPass)
//            }
//            return nil
//        }
//        public func setViewPort(encoder:MTLRenderCommandEncoder?){
//            encoder?.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(self.width), height: Double(self.height), znear: 0, zfar: 1))
//        }
//    }
//
//    public class Vsync:NSObject{
//        public typealias VsyncCallBack = ()->Bool
//        private var callback:VsyncCallBack?
//        public override init(){
//            super.init()
//        }
//        public func setCallBack(callback: @escaping ()->Bool) {
//            self.callback = callback
//            Thread {
//                let l = CADisplayLink(target: self, selector: #selector(self.callbackSelector(link:)))
//                l.add(to: RunLoop.current, forMode: .common)
//                RunLoop.current.run()
//            }.start()
//        }
//        @objc func callbackSelector(link:CADisplayLink){
//            guard let callback else { return }
//            if !callback(){
//                link.invalidate()
//            }
//        }
//    }
//}
