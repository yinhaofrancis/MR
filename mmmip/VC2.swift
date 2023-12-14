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
    override func didMoveToWindow() {
        super.didMoveToWindow()
        mtLayer.contentsScale = 3;
        mtLayer.drawableSize = CGSize(width: self.bounds.size.width * 3, height: self.bounds.size.height * 3)
        mtLayer.rasterizationScale = 3;
    }
    var mtLayer:CAMetalLayer{
        return self.layer as! CAMetalLayer
    }
    override class var layerClass: AnyClass{
        CAMetalLayer.self
    }
}
