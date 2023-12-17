//
//  Renderer.hpp
//  MRender
//
//  Created by wenyang on 2023/12/17.
//

#ifndef Renderer_hpp
#define Renderer_hpp

#include <iostream>
#include <glm/glm.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <glm/ext.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include <assimp/Importer.hpp>
#include <assimp/scene.h>
#include <assimp/postprocess.h>
#include <Metal/Metal.hpp>
#include "MRObject.hpp"

namespace MR {


class Renderer:virtual Object{
public:
    Renderer();
    ~Renderer();
    
    static Renderer& shared();
    
private:
    MTL::Device m_device;
    static Renderer *s_shared;
};

class Buffer:virtual Object {
public:
    Buffer();
    ~Buffer();
    void assign(const void * data,size_t size);
    
private:
    MTL::Buffer m_buffer;
};



};

#endif /* Renderer_hpp */
