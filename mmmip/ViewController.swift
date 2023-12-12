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

    let renderPass = RenderPass(render: .shared)
    let programe = RenderPipelineProgram()
    let vsync = Renderer.Vsync()
    let queue = try! Renderer.RenderQueue()
    override func viewDidLoad() {
        super.viewDidLoad()
        let depth = queue.renderer.defaultDepthState
        let layer = self.vc2View.mtLayer
        layer.pixelFormat = Configuration.ColorPixelFormat
        layer.device = queue.renderer.device
        
        var model = Model.sphere(size: [1,1,1], segments: [20,20])
        
        model.modelObject.model = simd_float4x4.translate(m: .identity, v: [-3,1,-3])
        
        var plant = Model.plant(size: [20,20,20], segments: [1,1])
        
        plant.modelObject.model = simd_float4x4.rotate(m: .identity, angle: .pi / -2, v: [0,0,1])
        
        var rmodel = try! RenderModel(vertexDescriptor: model.vertexDescription, depthState: depth)

        let materail = Material()
        
        let skm = Model.skybox(scale: 10)
        
        var sk = try! RenderSkyboxModel(vertexDescriptor: skm.vertexDescription, depth: queue.renderer.skyboxDepthState, model: skm)
        
        
        
        var c = CameraObject(projection: simd_float4x4.perspective(fovy: 45, aspect: 9.0 / 16.0, zNear: 1, zFar: 150), view: .lookat(eye: [8,8,8], center: [0,0,0], up: [0,1,0]), camera_pos: [8,8,8])
        var l = LightObject(light_pos: [-8,8,8], light_center: [0,0,0], is_point_light:  0)
        
        
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
                c.view = .lookat(eye: [x,5,z], center: [0,0,0], up: [0,1,0])
                c.camera_pos = [x,5,z]
                
                let buffer = try self.queue.createBuffer()
                let encoder = try self.renderPass.beginRender(buffer: buffer, layer: layer)
                
                guard let drawable = self.renderPass.drawable else {
                    encoder.endEncoding()
                    return true
                }
                try sk.draw(encoder: encoder, cameraModel: &c, material: materail, lightModel: &l)
                try rmodel.draw(encoder: encoder, 
                                model: model,
                                material: materail,
                               cameraModel: &c,
                                lightModel: &l)
                try rmodel.draw(encoder: encoder, 
                                model: plant,
                                material: materail,
                                cameraModel: &c,
                                lightModel: &l)
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



