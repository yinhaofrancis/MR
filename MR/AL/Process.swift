//
//  Process.swift
//  MR
//
//  Created by wenyang on 2023/12/11.
//

import Metal
import MetalKit
import simd
import Foundation


public class MSAAProcess{
    public let tileState:MTLRenderPipelineState
    public init(render:AL.Render) throws {
        let temp = MTLTileRenderPipelineDescriptor()
        let state = try render.device.makeRenderPipelineState(tileDescriptor: temp, options: MTLPipelineOption(rawValue: 0))
        self.tileState = state.0
    }
    
}
