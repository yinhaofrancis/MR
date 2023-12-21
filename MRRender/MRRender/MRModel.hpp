//
//  MRModel.hpp
//  MRRender
//
//  Created by wenyang on 2023/12/18.
//

#ifndef MRModel_hpp
#define MRModel_hpp

#include <stdio.h>

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




class Model{
    
    
    
public:
private:
    Assimp::Importer m_importer;
    aiScene* m_scene;
    std::string folderPath;
};
};

#endif /* MRModel_hpp */
