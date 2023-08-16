//
//  ViewController.h
//  FirstOpenCV
//
//  Created by Stan on 2023/8/12.
//

#import <UIKit/UIKit.h>
#import "TXLiteAVSDK_Professional/TXLiteAVSDK.h"
@interface ViewController : UIViewController


-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image;
@property(nonatomic,strong)V2TXLivePlayer *player;

@end

