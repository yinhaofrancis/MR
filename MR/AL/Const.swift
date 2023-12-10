//
//  Const.swift
//  MR
//
//  Created by wenyang on 2023/12/10.
//

import Metal
import MetalKit
import simd
import Foundation


public let ColorPixel:MTLPixelFormat = .bgra8Unorm_srgb

public let StencilPixel:MTLPixelFormat = .stencil8

public let DepthPixel:MTLPixelFormat = .depth32Float

public let DepthStencilPixel:MTLPixelFormat = .depth32Float_stencil8

public let MRbundleID = "com.yinhao.MR"

public let CurrentBundle = {
    
    Bundle(identifier: MRbundleID)!
    
}()
