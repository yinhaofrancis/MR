//
//  MRPrensentation.hpp
//  MRRender
//
//  Created by wenyang on 2023/12/18.
//

#ifndef MRPrensentation_hpp
#define MRPrensentation_hpp

#include <stdio.h>
#include "MRRenderer.hpp"

namespace MR {
class RenderScreen:virtual Object{
public:
    RenderScreen(Renderer& render = Renderer::shared(),Program& program = Program::shared());
    ~RenderScreen();
    void render(Texture& texture,Sampler& sampler,MTL::RenderCommandEncoder * encoder) const;
private:
    MTL::RenderPipelineState *m_state = nullptr;
};

class RenderScene:virtual Object{
public:
    RenderScene(MTL::VertexDescriptor* vertexDescriptor,Renderer& render = Renderer::shared(),Program& program = Program::shared());
    ~RenderScene();
    void render(MR::Mesh& mesh,MTL::RenderCommandEncoder * encoder) const;
private:
    MTL::RenderPipelineState *m_state = nullptr;
    MTL::DepthStencilState *m_depth = nullptr;
};

void lookAt(Camera& camera,glm::vec3 eye,glm::vec3 center,glm::vec3 up);

void perspective(Camera& camera,float fovy,float aspect,float near,float far);

void modelTransform(ModelTransform& transform,glm::mat4 matrix);

};

#endif /* MRPrensentation_hpp */
