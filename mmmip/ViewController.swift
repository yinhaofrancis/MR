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
        
        let model = Model.sphere(size: [1,1,1], segments: [20,20])
        
        var rmodel = try! RenderModel(vertexDescriptor: model.vertexDescription, depthState: depth)
        rmodel.modelObject.model = simd_float4x4.translate(m: .identity, v: [10,0,0])
        rmodel.modelObject.createNormalMatrix()
        let skm = Model.skybox(scale: 10)
        
        var sk = try! RenderSkyboxModel(vertexDescriptor: skm.vertexDescription, depth: queue.renderer.skyboxDepthState, model: skm)
        sk.ambient = .defaultTextureCube
        
        rmodel.diffuse = .defaultTexture
        rmodel.specular = .defaultSpecular
        rmodel.normal = .defaultNormal
        
        var c = CameraObject(projection: simd_float4x4.perspective(fovy: 45, aspect: 9.0 / 16.0, zNear: 1, zFar: 150), view: .lookat(eye: [8,8,8], center: [0,0,0], up: [0,1,0]), camera_pos: [8,8,8])
        var l = LightObject(light_pos: [-8,8,8], light_center: [0,0,0], is_point_light:  0)
        
        var rol:Float = 0.01
        
        TextureLoader.shared.texture(name: "sky") { r in
            sk.ambient = r
        }
        
        
        vsync.setCallBack { [weak self] in
            guard let self else {
                return false
            }
            do {
                rol += 0.01
                let x = cos(rol) * 8
                let z = sin(rol) * 8
                c.view = .lookat(eye: [x,2,z], center: [0,0,0], up: [0,1,0])
                c.camera_pos = [x,2,z]
                
                let buffer = try self.queue.createBuffer()
                let encoder = try self.renderPass.beginRender(buffer: buffer, layer: layer)
                
                guard let drawable = self.renderPass.drawable else {
                    encoder.endEncoding()
                    return true
                }
                try sk.draw(encoder: encoder, cameraModel: &c, lightModel: &l)
                try rmodel.draw(encoder: encoder, model: model,
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



