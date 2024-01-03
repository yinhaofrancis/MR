//
//  MRAnimation.hpp
//  MRRender
//
//  Created by wenyang on 2024/1/2.
//

#ifndef MRAnimation_hpp
#define MRAnimation_hpp

#include <stdio.h>
#include <vector>
#include <map>
#include "MRRenderer.hpp"
                                   
#include <MR/Constant.h>
#include <assimp/Importer.hpp>
#include <assimp/scene.h>
#include <assimp/postprocess.h>
namespace MR{

struct KeyAnimation{
    double time;
    simd_float4 transform;
};
struct Bone{
    simd_float4x4 m_offset;
    simd_float4x4 transform;
    std::vector<Bone *> children;
    Bone *m_parent;
    int boneId;
    std::string name;
};

struct AnimationGroup{
    std::vector<KeyAnimation> keyRotateAnimations;
    std::vector<KeyAnimation> keyScaleAnimations;
    std::vector<KeyAnimation> keyPositionAnimations;

    simd_float4x4 transform(double time);
    static void read(aiAnimation * animation,std::map<std::string,AnimationGroup>& groups);
    
};


class Animator:virtual Object{
public:
    Animator(aiBone ** bone,int count,aiNode * root);
    ~Animator();
    void loadAnimation(aiAnimation * animation);
    void update(double time,BoneBuffer* bone);
    simd_float4x4 rootInverse;
    void readRootInverse(aiNode* node);
private:
    std::map<int,Bone*> idex_map_bone;
    std::map<std::string,Bone*> map_bone;
    Bone* rootBone = nullptr;
    std::map<int,AnimationGroup> animationGroups;
};



};


#endif /* MRAnimation_hpp */
