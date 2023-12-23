//
//  ViewController.m
//  demo
//
//  Created by wenyang on 2023/12/17.
//

#import "ViewController.h"
#include <MRRender/Export.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mView.mtLayer.pixelFormat = MTLPixelFormatRGBA8Unorm_sRGB;
    self.mView.mtLayer.contentsScale = 3;
    
    beginMesh([NSBundle.mainBundle URLForResource:@"ball" withExtension:@"obj"].path.UTF8String);
    // Do any additional setup after loading the view.
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    
    drawMesh((__bridge void *)self.mView.mtLayer.nextDrawable);
}




-(mView*) mView{
    return (mView*)self.view;
}

@end
@implementation mView

- (CAMetalLayer *)mtLayer{
    return (CAMetalLayer *)self.layer;
}
+ (Class)layerClass{
    return CAMetalLayer.class;
}

@end
