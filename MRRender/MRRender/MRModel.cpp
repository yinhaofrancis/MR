//
//  MRModel.cpp
//  MRRender
//
//  Created by wenyang on 2023/12/18.
//

#include "MRModel.hpp"
#include "MRRenderer.hpp"
#include "Util.h"
#define STB_IMAGE_IMPLEMENTATION
#include <stb/stb_image.h>

using namespace MR;

Scene::Scene(std::string& url){
    unsigned int flags = aiProcess_Triangulate | aiProcess_FlipUVs | aiProcess_CalcTangentSpace | aiProcess_GenSmoothNormals | aiProcess_JoinIdenticalVertices;
    const aiScene * scene = m_importer.ReadFile(url, flags);
    std::filesystem::path filePath(url);
    std::filesystem::path folderPath = filePath.parent_path();
    m_folderPath = folderPath.string();
    if (!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode) {
        
        throw (MR::Error){"open model fail",1};
    }
    this->m_scene = (aiScene *)scene;
}
void Scene::loadMeshComponent(unsigned int componentSize, 
                              Mesh &m, unsigned int numVertice,
                              Mesh::VertexComponent vc,
                              aiVector3D *vertexBuffer) {
    int size = numVertice * componentSize * sizeof(float);
    float *vertex = new float[numVertice * componentSize];
    for(int i = 0;i < numVertice;i++){
        for (int j = 0; j < componentSize; j++) {
            if(j == 0){
                vertex[i * componentSize + j] = vertexBuffer[i].x;
            }
            if(j == 1){
                vertex[i * componentSize + j] = vertexBuffer[i].y;
            }
            if(j == 2){
                vertex[i * componentSize + j] = vertexBuffer[i].z;
            }
        }
    }
    m.buffer(size,vertex, vc);
    delete [] vertex;
}
void Scene::loadMeshColorComponent(unsigned int componentSize,
                              Mesh &m,
                              unsigned int numVertice,
                              aiColor4D *vertexBuffer) {
    int size = numVertice * componentSize * sizeof(float);
    float *vertex = new float[numVertice * componentSize];
    for(int i = 0;i < numVertice;i++){
        for (int j = 0; j < componentSize; j++) {
            if(j == 0){
                vertex[i * componentSize + j] = vertexBuffer[i].r;
            }
            if(j == 1){
                vertex[i * componentSize + j] = vertexBuffer[i].g;
            }
            if(j == 2){
                vertex[i * componentSize + j] = vertexBuffer[i].b;
            }
            if(j == 3){
                vertex[i * componentSize + j] = vertexBuffer[i].a;
            }
        }
    }
    m.buffer(size,vertex, Mesh::VertexComponent::Color);
    delete [] vertex;
}

MR::Mesh Scene::mesh(int index){
    auto amesh = m_scene->mMeshes[index];
    Mesh m;
    if (amesh->HasPositions()){
        Mesh::VertexComponent vc = Mesh::VertexComponent::Position;
        unsigned int numVertice = amesh->mNumVertices;
        aiVector3D * vertexBuffer = amesh->mVertices;
        unsigned int componentSize = 3;
        loadMeshComponent(componentSize, m, numVertice, vc, vertexBuffer);
    }
    if (amesh->HasTextureCoords(coordinate_count)){
        unsigned int numVertice = amesh->mNumVertices;
        aiVector3D * vertexBuffer = amesh->mTextureCoords[coordinate_count];
        unsigned int componentSize = amesh->mNumUVComponents[coordinate_count];
        Mesh::VertexComponent vc = Mesh::VertexComponent::TextureCoords;
        loadMeshComponent(componentSize, m, numVertice, vc, vertexBuffer);
    }
    if (amesh->HasNormals()){
        unsigned int numVertice = amesh->mNumVertices;
        aiVector3D * vertexBuffer = amesh->mNormals;
        unsigned int componentSize = 3;
        Mesh::VertexComponent vc = Mesh::VertexComponent::Normal;
        loadMeshComponent(componentSize, m, numVertice, vc, vertexBuffer);
    }
    if (amesh->HasTangentsAndBitangents()){
        unsigned int numVertice = amesh->mNumVertices;
        aiVector3D * vertexBuffer = amesh->mTangents;
        unsigned int componentSize = 3;
        Mesh::VertexComponent vc = Mesh::VertexComponent::Tangent;
        loadMeshComponent(componentSize, m, numVertice, vc, vertexBuffer);
    }
    if (amesh->HasTangentsAndBitangents()){
        unsigned int numVertice = amesh->mNumVertices;
        aiVector3D * vertexBuffer = amesh->mBitangents;
        unsigned int componentSize = 3;
        Mesh::VertexComponent vc = Mesh::VertexComponent::Bitangent;
        loadMeshComponent(componentSize, m, numVertice, vc, vertexBuffer);
    }
    if (amesh->HasVertexColors(0)){
        unsigned int numVertice = amesh->mNumVertices;
        aiColor4D* vertexBuffer = amesh->mColors[0];
        unsigned int componentSize = 4;

        loadMeshColorComponent(componentSize, m, numVertice, vertexBuffer);
    }
    if (amesh->HasFaces()){
        
        unsigned int count = 0;
        for (int i = 0;  i < amesh->mNumFaces; i++) {
            aiFace af = amesh->mFaces[i];
            count += af.mNumIndices;
        }
        m.indexType() = MTL::IndexTypeUInt32;
        uint32_t* buffer = new u_int32_t[count];
        int index = 0;
        for (int i = 0;  i < amesh->mNumFaces; i++) {
            aiFace af = amesh->mFaces[i];
            for (int j = 0; j < af.mNumIndices; j++) {
                buffer[index] = af.mIndices[j];
                index ++;
            }
        }
        m.buffer(count * sizeof(uint32_t), buffer, Mesh::VertexComponent::Index);
        m.vertexCount() = count;
    }else{
        m.vertexCount() = amesh->mNumVertices;
    }
    return m;
}
Texture Scene::loadTexture(aiTextureType textureType, aiMaterial *p_material, int textureIdex) {
    aiTextureMapping mapping;
    unsigned int uvindex;
    aiString path;
    aiTextureMapMode mmod;
    if (aiReturn_SUCCESS == p_material->GetTexture(textureType, textureIdex, &path,&mapping,&uvindex,nullptr,nullptr,&mmod)){
        int x = 0;
        int y = 0;
        int c = 0;
        std::string abpth = m_folderPath + "/" + path.C_Str();
        stbi_convert_iphone_png_to_rgb(true);
        auto data = stbi_load(abpth.c_str(),&x, &y, &c, 0);
        if(data == nullptr){
            std::cout << stbi_failure_reason() << std::endl;
        }
        Texture t(x, y, MTL::PixelFormatRGBA8Unorm);
        t.assign(x, y, c * x, data);
        return t;
    }
    throw (MR::Error){"create texture fail",0};
}

Materal Scene::phone(int index,int textureIdex){
    auto amesh = m_scene->mMeshes[index];
    auto p_material = m_scene->mMaterials[amesh->mMaterialIndex];
    Materal m = Materal::defaultMateral();
    m.m_diffuse = loadTexture(aiTextureType_DIFFUSE, p_material, textureIdex);
    m.m_specular = loadTexture(aiTextureType_SPECULAR, p_material, textureIdex);
    try {
        m.m_normal = loadTexture(aiTextureType_NORMALS, p_material, textureIdex);
    } catch (MR::Error e) {
        try {
            m.m_normal = loadTexture(aiTextureType_HEIGHT, p_material, textureIdex);
        } catch (MR::Error e) {
            
        }
        
    }
    return m;
}
Scene::~Scene(){
    if(ref_count() == 1){
        m_importer.FreeScene();
    }
}

