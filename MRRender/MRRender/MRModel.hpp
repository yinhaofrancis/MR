//
//  MRModel.hpp
//  MRRender
//
//  Created by wenyang on 2023/12/18.
//

#ifndef MRModel_hpp
#define MRModel_hpp

#include <stdio.h>
#include <vector>
#include <map>
#include "MRRenderer.hpp"
#include "MRAnimation.hpp"

#include <MR/Constant.h>
#include <assimp/Importer.hpp>
#include <assimp/scene.h>
#include <assimp/postprocess.h>

namespace MR {

enum TextureType{
    TextureTypeNone             =   0,
    TextureTypeDIFFUSE          =   1 << 1,
    TextureTypeSPECULAR         =   1 << 2,
    TextureTypeAMBIENT          =   1 << 3,
    TextureTypeEMISSIVE         =   1 << 4,
    TextureTypeHEIGHT           =   1 << 5,
    TextureTypeNORMALS          =   1 << 6,
    TextureTypeSHININESS        =   1 << 7,
    TextureTypeOPACITY          =   1 << 8,
    TextureTypeDISPLACEMENT     =   1 << 9,
    TextureTypeLIGHTMAP         =   1 << 10,
    TextureTypeREFLECTION       =   1 << 11,
    
    TextureTypeBASE_COLOR           =   1 << 12,
    TextureTypeNORMAL_CAMERA        =   1 << 13,
    TextureTypeEMISSION_COLOR       =   1 << 14,
    TextureTypeMETALNESS            =   1 << 15,
    TextureTypeDIFFUSE_ROUGHNESS    =   1 << 16,
    TextureTypeAMBIENT_OCCLUSION    =   1 << 17,
    TextureTypeSHEEN                =   1 << 19,
    TextureTypeCLEARCOAT            =   1 << 20,
    TextureTypeTRANSMISSION         =   1 << 21,
};





class Scene:virtual Object{
    
public:
    Scene(std::string& path);
    ~Scene();
    
    
    Mesh mesh(int index);

    bool hasTexture(aiTextureType textureType, aiMaterial *p_material, int textureIdex);
    
    Texture loadTexture(aiTextureType textureType, aiMaterial *p_material, int textureIdex);
    
    Materal phone(int index,int textureIdex);
    
    BoneBuffer* bone(int index);
    
    
    Animator animator(int index);
    
    aiAnimation* animation(int index);
    
private:
    
    void loadMeshComponent(unsigned int componentSize, Mesh &m, unsigned int numVertice, Mesh::VertexComponent vc, aiVector3D *vertexBuffer);
    void loadMeshColorComponent(unsigned int componentSize, Mesh &m, unsigned int numVertice, aiColor4D *vertexBuffer);
    void readVertexBone(Mesh& mesh,aiBone **bone,aiNode* node,int count,int boneCout);
private:
    Assimp::Importer m_importer;
    aiScene* m_scene;
    std::string m_folderPath;
    std::unordered_map<int, MR::Mesh*> map_mesh;
    std::unordered_map<std::string, MR::Texture>map_texture;
    int coordinate_count = 0;
    
};


};


struct TempVertexBone {
    float weight;
    std::vector<int> boundId;
};


#endif /* MRModel_hpp */
