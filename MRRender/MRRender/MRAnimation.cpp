//
//  MRAnimation.cpp
//  MRRender
//
//  Created by wenyang on 2024/1/2.
//

#include "MRAnimation.hpp"

void deletebone(MR::Bone * m){
    if(m != nullptr){
        for (auto i = m->children.begin(); i != m->children.end(); i++) {
            deletebone(*i);
        }
        delete m;
    }
}
MR::Bone * readMap(aiBone ** bone,int count,aiNode * root,MR::Bone * parent,std::map<int,MR::Bone *>& namemap){
    MR::Bone *cu = nullptr;
    for (int i = 0 ; i < count; i++) {
        std::string mName = root->mName.C_Str();
        std::string boneName = bone[i]->mName.C_Str();
        if (mName == boneName) {
            cu = new MR::Bone();
            cu->boneId = i + 1;
            cu->name = mName;
            memcpy(&cu->m_offset, &bone[i]->mOffsetMatrix.Transpose(), sizeof(cu->m_offset));
            cu->m_parent = parent;
            memcpy(&cu->transform, &root->mTransformation.Transpose(), sizeof(cu->transform));
            namemap[i + 1] = cu;
            for (int i = 0; i < root->mNumChildren; i++) {
                cu->children.push_back(readMap(bone, count, root->mChildren[i], cu, namemap));
            }
        }
    }
    if (cu == nullptr) {
        for (int i = 0; i < root->mNumChildren; i++) {
            cu = readMap(bone, count, root->mChildren[i], nullptr, namemap);
            if (cu != nullptr) {
                break;
            }
        }
    }
    return cu;
    
}


simd_float4x4 MR::AnimationGroup::transform(double time){
    double last = 0;
    auto lastIter = keyRotateAnimations.begin();
    simd_float4x4 m = (simd_float4x4) {(simd_float4){1,0,0,0}, {0,1,0,0}, {0,0,1,0} , {0,0,0,1}};
    for(auto i = keyRotateAnimations.begin(); i < keyRotateAnimations.end();i++){
        if(i->time > time){
            simd_float4 t = lastIter->transform + time / (i->time - last) * (i->transform - lastIter->transform);
            aiQuaternion qua;
            qua.x = t.x;
            qua.y = t.y;
            qua.z = t.z;
            qua.w = t.w;
            simd_float4x4 temp;
            aiMatrix4x4 tm(qua.GetMatrix().Transpose());
            memcpy(&temp, &tm, sizeof(temp));
            m = simd_mul(temp, m);
            break;
        }else if(i->time == time){
            aiQuaternion qua;
            qua.x = i->transform.x;
            qua.y = i->transform.y;
            qua.z = i->transform.z;
            qua.w = i->transform.w;
            simd_float4x4 temp;
            aiMatrix4x4 tm(qua.GetMatrix().Transpose());
            memcpy(&temp, &tm, sizeof(temp));
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
            MR::glmTosimd(mat, temp);
            m = simd_mul(temp, m);
            break;
        }else if(i->time == time){
            auto mat = glm::scale(glm::mat4(1),glm::vec3(i->transform.x,i->transform.y,i->transform.z));
            simd_float4x4 temp;
            MR::glmTosimd(mat, temp);
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
            MR::glmTosimd(mat, temp);
            m = simd_mul(temp, m);
            break;
        }else if(i->time == time){
            auto mat = glm::translate(glm::mat4(1),glm::vec3(i->transform.x,i->transform.y,i->transform.z));
            simd_float4x4 temp;
            MR::glmTosimd(mat, temp);
            m = simd_mul(temp, m);
            break;
        }else{
            last = i->time;
            lastIter = i;
        }
    }
    return m;
}



void MR::AnimationGroup::read(aiAnimation * animation,std::map<std::string,AnimationGroup>& groups){
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
        groups[animation->mChannels[i]->mNodeName.C_Str()] = g;
    }
}

MR::Animator::Animator(aiBone ** bone,int count,aiNode * root){
    
    rootBone = readMap(bone, count, root, nullptr, idex_map_bone);
    readRootInverse(root);
}
void MR::Animator::loadAnimation(aiAnimation * animation){
    animationGroups.clear();
    std::map<std::string,AnimationGroup> map_group;
    MR::AnimationGroup::read(animation,map_group);
    for (auto a = idex_map_bone.begin(); a != idex_map_bone.end(); a++) {
        animationGroups[a->first] = map_group[a->second->name];
    }
}
MR::Animator::~Animator(){
    if(ref_count() == 1 && rootBone != nullptr){
        deletebone(rootBone);
    }
}

void readAnimation(MR::Bone *bone,
                   simd_float4x4 parent,
                   simd_float4x4 globel_inverse,
                   std::map<int,simd_float4x4>& in,
                   std::map<int,simd_float4x4>& out){
    if(bone == nullptr){
        return;
    }
    auto matrx = in[bone->boneId];
    simd_float4x4 current = simd_mul(parent, matrx);
    out[bone->boneId] =  simd_mul(globel_inverse,simd_mul(current,bone->m_offset));
    for (auto a = bone->children.begin(); a != bone->children.end(); a++) {
        readAnimation(*a, current,globel_inverse, in,out);
    }
}

void MR::Animator::update(double time,BoneBuffer* bone){
    std::map<int,simd_float4x4> out;
    std::map<int,simd_float4x4> in;
    for (auto i = animationGroups.begin(); i != animationGroups.end(); i++) {
        in[i->first] = i->second.transform(time);
    }
    simd_float4x4 m = (simd_float4x4) {(simd_float4){1,0,0,0}, {0,1,0,0}, {0,0,1,0} , {0,0,0,1}};
    readAnimation(rootBone, m,simd_inverse(rootBone->transform), in, out);
    for (auto i = out.begin(); i != out.end(); i++) {
        bone[i->first].content.matrix = i->second;
        bone[i->first].content.normalMatrix = simd_inverse(simd_transpose(i->second));
        
    }
}

void MR::Animator::readRootInverse(aiNode* node){
    memcpy(&rootInverse, &node->mTransformation.Transpose(), sizeof(rootInverse));
    rootInverse = simd_inverse(rootInverse);
}
