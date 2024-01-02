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
    if (amesh->HasBones()){
        auto count = m_scene->mMeshes[index]->mNumVertices;
        auto boneCount = m_scene->mMeshes[index]->mNumBones;
        readVertexBone(m, m_scene->mMeshes[index]->mBones, m_scene->mRootNode, count, boneCount);
        auto bonebuf = bone(index);
        m.buffer((boneCount + 1) * sizeof(BoneBuffer) , bonebuf, Mesh::Bone);
        delete [] bonebuf;
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
bool Scene::hasTexture(aiTextureType textureType, aiMaterial *p_material, int textureIdex){
    aiString path;
    return aiReturn_SUCCESS == p_material->GetTexture(textureType, textureIdex, &path);
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
    if (hasTexture(aiTextureType_DIFFUSE, p_material, textureIdex)){
        m.m_diffuse = loadTexture(aiTextureType_DIFFUSE, p_material, textureIdex);
    }
    if (hasTexture(aiTextureType_SPECULAR, p_material, textureIdex)){
        m.m_specular = loadTexture(aiTextureType_SPECULAR, p_material, textureIdex);
    }
    if(hasTexture(aiTextureType_NORMALS,p_material, textureIdex)){
        m.m_normal = loadTexture(aiTextureType_NORMALS, p_material, textureIdex);
    }
    if(hasTexture(aiTextureType_HEIGHT, p_material, textureIdex)){
        m.m_normal = loadTexture(aiTextureType_HEIGHT, p_material, textureIdex);
    }
    return m;
}


void  Scene::readVertexBone(Mesh& mesh,aiBone **bone,aiNode* node,int count,int boneCout){
    std::vector<std::vector<float>> vector;
    std::vector<std::vector<int32_t>> map;
    vector.resize(count);
    map.resize(count);
    for (int i = 0; i < boneCout; i ++) {
        for (int j = 0; j < bone[i]->mNumWeights; j++) {
            auto idex = bone[i]->mWeights[j].mVertexId;
            vector[idex].push_back(bone[i]->mWeights[j].mWeight);
            map[idex].push_back(i + 1);
        }
    }
    VertexBoneBuffer* m = new VertexBoneBuffer[count + 1];
    m->count = count;
    for (int i = 1; i <= count; i++) {
        memcpy(m[i].content.boneId, map[i - 1].data(), sizeof(int32_t) * fmin(map[i - 1].size(),vertex_boneId_buffer_size));
        
        memcpy(m[i].content.weight, vector[i - 1].data(), sizeof(float) * fmin(vector[i - 1].size(),vertex_boneId_buffer_size));
    }
    mesh.buffer(sizeof(VertexBoneBuffer) * (count + 1), m, Mesh::BoneMap);
    delete [] m;
}


void readBone(BoneBuffer* buffer,aiBone **bone,aiNode* node,int parent,int count){
    int current = 0;
    for (int i = 0; i < count ; i++) {
        std::string key(bone[i]->mName.C_Str());
        std::string name(node->mName.C_Str());
        if(name == key){
            simd_float4x4 m;
            m.columns[0] = {1,0,0,0};
            m.columns[1] = {0,1,0,0};
            m.columns[2] = {0,0,1,0};
            m.columns[3] = {0,0,0,1};
            buffer[i].content.matrix = m;
            buffer[i].content.normalMatrix = m;
            buffer[i].content.boneId = i + 1;
            current = i + 1;
            if (parent != 0){
                buffer[i].content.parentId = parent;
            }else{
                buffer[i].content.parentId = 0;
            }
            std::cout << current << "|" << parent << "|" << name << std::endl;
            break;
        }
    }
    for (int i = 0; i < node->mNumChildren; i++) {
        readBone(buffer,bone,node->mChildren[i],current,count);
    }
    
}
BoneBuffer* Scene::bone(int index){
    auto bone = m_scene->mMeshes[index]->mBones;
    auto cout = m_scene->mMeshes[index]->mNumBones;
    BoneBuffer* buffer = new BoneBuffer[cout + 1];
    buffer->count = cout;
    readBone(buffer + 1,bone,m_scene->mRootNode,0,cout);
    return buffer;
}
Animator Scene::animator(int index){
    aiAnimation* animation = m_scene->mAnimations[index];
    Animator animator;
    animator.read(m_scene->mMeshes[index]->mBones, m_scene->mRootNode, animation, m_scene->mMeshes[index]->mNumBones);
    return animator;
}
Scene::~Scene(){
    if(ref_count() == 1){
        m_importer.FreeScene();
    }
}


void Animator::read(aiBone **bone,aiNode* node,aiAnimation * animation,int count){
    std::map<std::string,int> map_bone_idex;
    std::map<std::string, aiBone*> map_bone_ref;

    for(int i = 1; i <= count; i++){
        std::string key(bone[i - 1]->mName.C_Str());
        map_bone_idex[key] = i;
        map_bone_ref[key] = bone[i - 1];
        index_bone_ref[i] = bone[i - 1];
    }
    createMapParent(map_bone_ref, node, map_bone_idex, map_parent, count);
    for (int i = 0; i < animation->mNumChannels; i++) {
        AnimationGroup g;
        for (int j = 0; j < animation->mChannels[i]->mNumPositionKeys; j++) {
            KeyAnimation kpa;
            auto glmm = glm::vec4(animation->mChannels[i]->mPositionKeys[j].mValue.x,
                                  animation->mChannels[i]->mPositionKeys[j].mValue.y,
                                  animation->mChannels[i]->mPositionKeys[j].mValue.z,1
                                  );
            
            MR::glmTosimd(glmm, kpa.transform);
            kpa.time = animation->mChannels[i]->mPositionKeys[j].mTime;
            
            g.keyPositionAnimations.push_back(kpa);
        }
        for (int j = 0; j < animation->mChannels[i]->mNumScalingKeys; j++) {
            KeyAnimation kpa;
            auto glmm = glm::vec4(animation->mChannels[i]->mScalingKeys[j].mValue.x,
                                  animation->mChannels[i]->mScalingKeys[j].mValue.y,
                                  animation->mChannels[i]->mScalingKeys[j].mValue.z,1
                                  );
            
            MR::glmTosimd(glmm, kpa.transform);

            kpa.time = animation->mChannels[i]->mScalingKeys[j].mTime;
            g.keyScaleAnimations.push_back(kpa);
        }
        for (int j = 0; j < animation->mChannels[i]->mNumRotationKeys; j++) {
            KeyAnimation kpa;
            glm::vec4 v(animation->mChannels[i]->mRotationKeys[j].mValue.x,
                        animation->mChannels[i]->mRotationKeys[j].mValue.y,
                        animation->mChannels[i]->mRotationKeys[j].mValue.z,
                        animation->mChannels[i]->mRotationKeys[j].mValue.w);
            kpa.time = animation->mChannels[i]->mRotationKeys[j].mTime;
            MR::glmTosimd(v, kpa.transform);
            g.keyRotateAnimations.push_back(kpa);
        }
        std::string key = animation->mChannels[i]->mNodeName.C_Str();
        int bid = map_bone_idex[key];
        skeletonMapAnimations[bid] = g;
    }
    
}
void Animator::createMapParent(std::map<std::string, aiBone*> &bone,aiNode* node,std::map<std::string,int> map_bone,std::map<int,int>& map_parent,int count){
    
    std::string key(node->mName.C_Str());
    if (bone.find(key) != bone.end() && node->mParent != nullptr){
        
        std::string parentKey = node->mParent->mName.C_Str();
        int parent = map_bone[parentKey];
        if(parent != 0){
            int current = map_bone[key];
            map_parent[current] = parent;
        }
    }
    for (int i = 0; i < node->mNumChildren; i++) {
        createMapParent(bone, node->mChildren[i], map_bone, map_parent, count);
    }
    
}
void Animator::transform(double time,BoneBuffer* bondBuffer){
    std::map<int, simd_float4x4> bone_tranform;
    std::map<int, simd_float4x4> bone_relate_transform;
    getState(bone_tranform, time);
    getRecursiveState(bone_relate_transform, bone_tranform, time);
    for (int i = 1; i <= bondBuffer->count; i++) {
        bondBuffer[i].content.matrix = bone_relate_transform[i];
        bondBuffer[i].content.normalMatrix = simd_inverse(simd_transpose(bone_relate_transform[i]));
    }
    
}


simd_float4x4 AnimationGroup::transform(double time){
    double last = 0;
    auto lastIter = keyRotateAnimations.begin();
    simd_float4x4 m = (simd_float4x4) {(simd_float4){1,0,0,0}, {0,1,0,0}, {0,0,1,0} , {0,0,0,1}};
    for(auto i = keyRotateAnimations.begin(); i < keyRotateAnimations.end();i++){
        if(i->time > time){
            simd_float4 t = lastIter->transform + time / (i->time - last) * (i->transform - lastIter->transform);
            auto mat = glm::rotate(glm::mat4(1), t.w, glm::vec3(t.x,t.y,t.z));
            simd_float4x4 temp;
            glmTosimd(mat, temp);
            m = simd_mul(temp, m);
            break;
        }else if(i->time == time){
            auto mat = glm::rotate(glm::mat4(1), i->transform.w, glm::vec3(i->transform.x,i->transform.y,i->transform.z));
            simd_float4x4 temp;
            glmTosimd(mat, temp);
            m = simd_mul(temp, m);
            break;
        }else{
            last = i->time;
            lastIter = i;
        }
    }
    last = 0;
    lastIter = keyScaleAnimations.begin();
    for(auto i = keyScaleAnimations.begin(); i < keyScaleAnimations.end();i++){
        if(i->time > time){
            simd_float4 t = lastIter->transform + time / (i->time - last) * (i->transform - lastIter->transform);
            auto mat = glm::scale(glm::mat4(1),glm::vec3(t.x,t.y,t.z));
            simd_float4x4 temp;
            glmTosimd(mat, temp);
            m = simd_mul(temp, m);
            break;
        }else if(i->time == time){
            auto mat = glm::scale(glm::mat4(1),glm::vec3(i->transform.x,i->transform.y,i->transform.z));
            simd_float4x4 temp;
            glmTosimd(mat, temp);
            m = simd_mul(temp, m);
            break;
        }else{
            last = i->time;
            lastIter = i;
        }
    }
    last = 0;
    lastIter = keyPositionAnimations.begin();
    for(auto i = keyPositionAnimations.begin(); i < keyPositionAnimations.end();i++){
        if(i->time > time){
            simd_float4 t = lastIter->transform + time / (i->time - last) * (i->transform - lastIter->transform);
            auto mat = glm::translate(glm::mat4(1),glm::vec3(t.x,t.y,t.z));
            simd_float4x4 temp;
            glmTosimd(mat, temp);
            m = simd_mul(temp, m);
            break;
        }else if(i->time == time){
            auto mat = glm::translate(glm::mat4(1),glm::vec3(i->transform.x,i->transform.y,i->transform.z));
            simd_float4x4 temp;
            glmTosimd(mat, temp);
            m = simd_mul(temp, m);
            break;
        }else{
            last = i->time;
            lastIter = i;
        }
    }
    return m;
}

void Animator::getState(std::map<int,simd_float4x4> &outTransform,double time){
    for (auto a = skeletonMapAnimations.begin(); a != skeletonMapAnimations.end(); a++) {
        simd_float4x4 offset;
        memcpy(&offset, &index_bone_ref[a->first]->mOffsetMatrix, sizeof(simd_float4x4));
        simd_float4x4 inverse = simd_inverse(offset);
        outTransform[a->first] = simd_mul(inverse, simd_mul(a->second.transform(time), offset));
    }
}

void Animator::getRecursiveState(std::map<int,simd_float4x4> &outTransform,
                                 std::map<int,simd_float4x4> &inTransform,double time){
    for (auto a = inTransform.begin(); a != inTransform.end(); a++) {
        simd_float4x4 offset = a->second;
        int curret = a->first;
        while (map_parent.find(curret) != map_parent.end()) {
            curret = map_parent[curret];
            if(curret == 0){
                break;
            }
            auto paret = inTransform[curret];
            offset = simd_mul(paret, offset);
        }
        outTransform[a->first] = offset;
    }
}
