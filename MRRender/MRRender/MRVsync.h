//
//  MRVsyc.h
//  MRRender
//
//  Created by wenyang on 2023/12/27.
//

#ifndef MRVsyc_h
#define MRVsyc_h
#include "MRObject.hpp"
namespace MR{
class Vsync:virtual Object{
public:
    typedef std::function<bool(void)> SyncCallBack;
    Vsync(SyncCallBack);
    ~Vsync();
};


};



#endif /* MRVsyc_h */
