//
//  MRObject.hpp
//  MRender
//
//  Created by wenyang on 2023/12/17.
//

#ifndef MRObject_hpp
#define MRObject_hpp

#include "util.h"
namespace MR {
class Object{
    
public:
    Object();
    Object(const Object&);
    Object(const Object &&);
    Object& operator =(const Object&);
    Object& operator =(const Object &&);
    int ref_count();
    virtual ~Object();
    virtual void dealloc();
protected:
    Object& retain();
    int release();
private:
    int *m_ref_count;
    std::mutex m_lock;
};

};

#endif /* MRObject_hpp */
