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
    // Do any additional setup after loading the view.
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    
    uint8_t buffer [16] {
        255,0,0,255,
        0,255,0,255,
        0,0,255,255,
        255,0,255,255,
    };
    renderBitmap((__bridge void *)self.mView.mtLayer.nextDrawable, 2, 2, 8, (const void *)buffer);
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
