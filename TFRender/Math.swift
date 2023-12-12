//
//  math.swift
//  MR
//
//  Created by wenyang on 2023/12/8.
//

import Foundation
import simd
import Accelerate
import Spatial

extension simd_float4x4 {
    public static func perspective(fov:Float,width:Float,height:Float,zNear:Float,zFar:Float) -> simd_float4x4{
        assert(width > 0);
        assert(height > 0);
        assert(fov > 0);

        let rad = fov;
        let h = cos(0.5 * rad) / sin(0.5 * rad);
        let w = h * height / width; ///todo max(width , Height) / min(width , Height)?

        var Result = simd_float4x4.zero
        Result[0][0] = w;
        Result[1][1] = h;
        Result[2][2] = -(zFar + zNear) / (zFar - zNear);
        Result[2][3] = -1;
        Result[3][2] = -(2 * zFar * zNear) / (zFar - zNear);
        return Result;
    }
    
    public static func infinitePerspective(fovy:Float,aspect:Float,zNear:Float) -> simd_float4x4{
        let range = tan(fovy / 2.0) * zNear;
        let left = -range * aspect;
        let right = range * aspect;
        let bottom = -range;
        let top = range;

        var Result = simd_float4x4.zero
        Result[0][0] = (2.0 * zNear) / (right - left);
        Result[1][1] = (2.0 * zNear) / (top - bottom);
        Result[2][2] = -1.0;
        Result[2][3] = -1.0;
        Result[3][2] = -2.0 * zNear;
        return Result;
    }
    public static func perspective(fovy:Float, aspect:Float, zNear:Float, zFar:Float) -> simd_float4x4
    {
        let  tanHalfFovy = tan(fovy / 2.0);

        var Result = simd_float4x4.zero
        Result[0][0] = 1.0 / (aspect * tanHalfFovy);
        Result[1][1] = 1.0 / (tanHalfFovy);
        Result[2][2] = -(zFar + zNear) / (zFar - zNear);
        Result[2][3] = -1.0;
        Result[3][2] = -(2.0 * zFar * zNear) / (zFar - zNear);
        return Result;
    }
    public static func frustum(left:Float,right:Float,top:Float,bottom:Float,nearVal:Float, farVal:Float)->simd_float4x4{
        var Result = float4x4.zero
        Result[0][0] = (2.0 * nearVal) / (right - left);
        Result[1][1] = (2.0 * nearVal) / (top - bottom);
        Result[2][0] = (right + left) / (right - left);
        Result[2][1] = (top + bottom) / (top - bottom);
        Result[2][2] = -(farVal + nearVal) / (farVal - nearVal);
        Result[2][3] = -1.0;
        Result[3][2] = -(2.0 * farVal * nearVal) / (farVal - nearVal);
        return Result;
    }
    
    public static func ortho(left:Float,right:Float,bottom:Float,top:Float,zNear:Float,zFar:Float)->simd_float4x4
    {
        var Result = simd_float4x4.identity
        Result[0][0] = 2.0 / (right - left);
        Result[1][1] = 2.0 / (top - bottom);
        Result[2][2] = -2.0 / (zFar - zNear);
        Result[3][0] = -(right + left) / (right - left);
        Result[3][1] = -(top + bottom) / (top - bottom);
        Result[3][2] = zNear / (zFar - zNear);
        return Result;
    }
    public static let identity:simd_float4x4 = {
        return simd_float4x4(rows: [
            [1,0,0,0],
            [0,1,0,0],
            [0,0,1,0],
            [0,0,0,1]
        ])
    }()
    public static let zero:simd_float4x4 = {
        return simd_float4x4(rows: [
            [0,0,0,0],
            [0,0,0,0],
            [0,0,0,0],
            [0,0,0,0]
        ])
    }()

    public static func translate(m:simd_float4x4,v:simd_float3)->simd_float4x4{
        var Result = m;
        Result[3] = m[0] * v[0] + m[1] * v[1] + m[2] * v[2] + m[3];
        return Result;
    }
    public static func scale(m:simd_float4x4,v:simd_float3)->simd_float4x4{
        var Result = m;
        Result[0] = m[0] * v[0];
        Result[1] = m[1] * v[1];
        Result[2] = m[2] * v[2];
        Result[3] = m[3];
        return Result;
    }
    public static func inverseTranspose(m:simd_float4x4)->simd_float4x4{
        simd_transpose(simd_inverse(m))
    }
    public static func lookat(eye:simd_float3,center:simd_float3,up:simd_float3)->simd_float4x4{
        let f = (normalize(center - eye));
        let s = (normalize(cross(f, up)));
        let u = (cross(s, f));

        var Result = simd_float4x4.identity
        Result[0][0] = s.x;
        Result[1][0] = s.y;
        Result[2][0] = s.z;
        Result[0][1] = u.x;
        Result[1][1] = u.y;
        Result[2][1] = u.z;
        Result[0][2] = -f.x;
        Result[1][2] = -f.y;
        Result[2][2] = -f.z;
        Result[3][0] = -dot(s, eye);
        Result[3][1] = -dot(u, eye);
        Result[3][2] = dot(f, eye);
        return Result;
    }
    public static func rotate(m:simd_float4x4,angle:Float,v:simd_float3)->simd_float4x4{
        let a = angle;
        let c = cos(a);
        let s = sin(a);

        let axis = normalize(v);
        let temp = (1 - c) * axis;

        var Rotate = simd_float4x4();
        Rotate[0][0] = c + temp[0] * axis[0];
        Rotate[0][1] = temp[0] * axis[1] + s * axis[2];
        Rotate[0][2] = temp[0] * axis[2] - s * axis[1];

        Rotate[1][0] = temp[1] * axis[0] - s * axis[2];
        Rotate[1][1] = c + temp[1] * axis[1];
        Rotate[1][2] = temp[1] * axis[2] + s * axis[0];

        Rotate[2][0] = temp[2] * axis[0] + s * axis[1];
        Rotate[2][1] = temp[2] * axis[1] - s * axis[0];
        Rotate[2][2] = c + temp[2] * axis[2];

        var Result = simd_float4x4()
        Result[0] = m[0] * Rotate[0][0] + m[1] * Rotate[0][1] + m[2] * Rotate[0][2];
        Result[1] = m[0] * Rotate[1][0] + m[1] * Rotate[1][1] + m[2] * Rotate[1][2];
        Result[2] = m[0] * Rotate[2][0] + m[1] * Rotate[2][1] + m[2] * Rotate[2][2];
        Result[3] = m[3];
        return Result;
    }

    public var matrix_3x3:simd_float3x3{
        simd_float3x3(columns: (
            simd_float3(self.columns.0.x, self.columns.0.y,self.columns.0.z),
            simd_float3(self.columns.1.x, self.columns.1.y,self.columns.1.z),
            simd_float3(self.columns.2.x, self.columns.2.y,self.columns.2.z)
        ))
    }
}

