//
//  MRThread.m
//  MRRender
//
//  Created by wenyang on 2023/12/27.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "MRThread.h"
#import "MRVsync.h"
using namespace MR;



@implementation OMRLink



- (void)run:(BOOL (^)())callback {
    self.callback = callback;
    CADisplayLink* l = [CADisplayLink displayLinkWithTarget:self selector:@selector(runCall:)];
    [[NSThread.alloc initWithBlock:^{
        [l addToRunLoop:NSRunLoop.currentRunLoop forMode:NSDefaultRunLoopMode];
    }] start];
}
- (void)runCall:(CADisplayLink *)lik{
    if(!self.callback()){
        [lik invalidate];
    }
}
@end

Vsync::Vsync(SyncCallBack call){
    [[[OMRLink alloc] init] run:^BOOL{
        return call();
    }];
}
Vsync::~Vsync(){
    
}
