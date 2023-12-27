//
//  MRThread.h
//  MRRender
//
//  Created by wenyang on 2023/12/27.
//

#ifndef MRThread_h
#define MRThread_h
@interface OMRLink:NSObject
@property(nonatomic,copy) BOOL (^callback)();
- (void)run:(BOOL (^)())callback;
@end

#endif /* MRThread_h */
