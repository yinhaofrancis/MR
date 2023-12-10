//
//  VC2.swift
//  mmmip
//
//  Created by wenyang on 2023/12/10.
//

import UIKit
import MR
import simd

class VC2: UIViewController {
    
    
    let helper:AL.Helper = .shared
    
    lazy var timer = helper.makeTimer()
    
    override func viewDidLoad() {
        let layer = self.vc2View.mtLayer
        let scene = self.helper.makeScene()
        
        let ll = try! helper.ball(size: [0.3,0.3,0.3])
        let ball = try! helper.ball(size: [1,1,1])
        let box =  try! helper.box(size: [1,1,1])
        let plan = try! helper.plant(size: [1,1,1])
        plan.model.pointee.model = simd_float4x4.rotate(m: simd_float4x4.scale(m: .identity, v: [10,10,10]), angle: .pi / -2, v: [0,0,1])
        
        box.model.pointee.model = simd_float4x4.translate(m: .identity, v: [2,1,0])
        ball.model.pointee.model = simd_float4x4.translate(m: .identity, v: [-2,1,0])
        let sky = try! helper.skybox(size: [10,10,10], scale:10)

        ll.model.pointee.model = simd_float4x4.translate(m: .identity, v: scene.light.position)
        scene.renderables.append(ball)
        scene.renderables.append(box)
        scene.renderables.append(sky)
        scene.renderables.append(plan)
        scene.renderables.append(ll)
        scene.camera.position =  [-15,15,15]
        ball.loadModel()
        box.loadModel()
        sky.loadModel()
        plan.loadModel()
        ll.loadModel()
        var a = 0.0
        TextureLoader.shared.texture(name: "sky") { tex in
            sky.ambient = tex

        }
        TextureLoader.shared.texture(name: "container_normal") { tex in
            box.normal = tex
            ball.normal = tex
        }
        
        timer.setCallBack {[weak layer,weak self] in
            let x:Float = Float(cos(a) * 10.0)
            let z:Float = Float(sin(a) * 10.0)
//            scene.light.position = [x,10,z]
//            box.model.pointee.model = simd_float4x4.rotate(m: simd_float4x4.translate(m: .identity, v: [2,1,0]), angle: Float(a), v: [0,1,0])
//            box.loadModel()
            ball.model.pointee.model = simd_float4x4.rotate(m: simd_float4x4.translate(m: .identity, v: [-2,1,0]), angle: Float(a), v: [0,1,0])
            ball.loadModel()
            
            a += 0.01
            guard let self else {
                return false
            }
            guard let layer else {return true}
            scene.camera.aspect = Float(layer.drawableSize.width / layer.drawableSize.height)
            scene.loadModel()
            guard let buffer = self.helper.queue.createBuffer() else {return true}
            
            guard let encoder = self.helper.renderPass.beginRender(buffer: buffer, layer: layer) else { return true }
            self.helper.renderPass.setViewPort(encoder: encoder);
            guard let drawable = self.helper.renderPass.drawable else {return true}
            scene.draw(encoder: encoder)
            encoder.endEncoding()
            buffer.present(drawable)
           
            buffer.commit()
            buffer.waitUntilCompleted()
            return true
        }
    }
    
    public var vc2View:VC2View{
        return self.view as! VC2View
    }

}

class VC2View:UIView{
    
    var mtLayer:CAMetalLayer{
        return self.layer as! CAMetalLayer
    }
    override class var layerClass: AnyClass{
        CAMetalLayer.self
    }
}
