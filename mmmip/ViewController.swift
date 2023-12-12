////
////  ViewController.swift
////  mmmip
////
////  Created by wenyang on 2023/12/8.
////
//
import UIKit
import TFRender


class VC3:UIViewController{

    
    let programe = RenderPipelineProgram()
    let vsync = Renderer.Vsync()
    let queue = try! Renderer.RenderQueue()
    override func viewDidLoad() {
        super.viewDidLoad()
        let depth = queue.renderer.defaultDepthState
        let layer = self.vc2View.mtLayer
        layer.pixelFormat = Configuration.ColorPixelFormat
        layer.device = queue.renderer.device
        
        
        //模型
        var model = Model.sphere(size: [1,1,1], segments: [20,20])
        
        model.modelObject.model = simd_float4x4.translate(m: .identity, v: [-3,1,-3])
        
        var plant = Model.plant(size: [20,20,20], segments: [1,1])
        
        plant.modelObject.model = simd_float4x4.rotate(m: .identity, angle: .pi / -2, v: [0,0,1])
        
        let skm = Model.skybox(scale: 10)
        
        // 材質
        let materail = Material()
        
        let shadow = Shadow()
        
        //渲染程序
        var rmodel = try! RenderModel(vertexDescriptor: model.vertexDescription, depthState: depth)

        var sk = try! RenderSkyboxModel(vertexDescriptor: skm.vertexDescription, depth: queue.renderer.skyboxDepthState, model: skm)
        
        var shadowPro = try! RenderShadowModel(vertexDescriptor: model.vertexDescription, depth: queue.renderer.defaultDepthState)
        
        var c = Camera()
        
        var l = Light()
//        l.position = [-20,20,20]
        
        let renderPass = RenderPass(render: .shared)
        let depthRenderPass = RenderPass(render: .shared)
        
        var rol:Float = 0.01
        
        TextureLoader.shared.texture(name: "sky") { r in
            materail.ambient = r
        }
        
        
        vsync.setCallBack { [weak self] in
            guard let self else {
                return false
            }
            do {
                rol += 0.01
                let x = cos(rol) * 13
                let z = sin(rol) * 13
                c.position = [x,5,z]
                var buffer = try self.queue.createBuffer()
                let shadowe = try depthRenderPass.beginDepth(buffer: buffer, width: 1024, height: 1024)
                shadowPro.begin(encoder: shadowe)
                shadowPro.bindScene(encoder: shadowe, cameraModel: c, lightModel: l)
                try shadowPro.draw(encoder: shadowe, model: model)
                try shadowPro.draw(encoder: shadowe, model: plant)
                shadowe.endEncoding()
                shadow.globelShadow = depthRenderPass.depthTexture

                
                let encoder = try renderPass.beginRender(buffer: buffer, layer: layer)
                
                guard let drawable = renderPass.drawable else {
                    encoder.endEncoding()
                    return true
                }
                sk.begin(encoder: encoder)
                sk.bindScene(encoder: encoder, cameraModel: c, lightModel: l)
                try sk.draw(encoder: encoder,material: materail)
                rmodel.begin(encoder: encoder)
                rmodel.bindScene(encoder: encoder, cameraModel: c, lightModel: l)
                materail.diffuse = Renderer.Texture.defaultTexture
                try rmodel.draw(encoder: encoder,
                                model: model,
                                material: materail,
                                shadow: shadow)
                materail.diffuse = Renderer.Texture(texture: shadow.globelShadow!, samplerState: Renderer.Sampler.defaultSampler.samplerState)
                try rmodel.draw(encoder: encoder,
                                model: plant,
                                material: materail,
                                shadow: shadow)
                encoder.endEncoding()
                buffer.present(drawable)
                buffer.commit()
                
            } catch   {
                print(error)
            }
            return true
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

    }
    
    public var vc2View:VC2View{
        return self.view as! VC2View
    }
    
}



