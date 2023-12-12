//
//  VC2.swift
//  mmmip
//
//  Created by wenyang on 2023/12/10.
//

import UIKit
//import MR
import simd

class VC2View:UIView{
    
    var mtLayer:CAMetalLayer{
        return self.layer as! CAMetalLayer
    }
    override class var layerClass: AnyClass{
        CAMetalLayer.self
    }
}
