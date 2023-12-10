////
////  ViewController.swift
////  mmmip
////
////  Created by wenyang on 2023/12/8.
////
//
import UIKit
import MR


class VC3:UIViewController{
    var helper:AL.Helper = .shared
    lazy var v = helper.render.checkerboard!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        v.samplerState = helper.render.defaultNearestSampler
        
        
        helper.textureRender.render(queue: helper.queue, renderPass: helper.renderPass, texture:v , layer: self.vc2View.mtLayer)
    }
    
    public var vc2View:VC2View{
        return self.view as! VC2View
    }
    
}
