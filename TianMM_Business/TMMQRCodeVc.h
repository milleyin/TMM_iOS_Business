//
//  TMMQRCodeVcViewController.h
//  TianMM
//
//  Created by cocoa on 15/9/24.
//  Copyright © 2015年 cocoa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^QRCodeBlock)(NSString *Url);

@interface TMMQRCodeVc : UIViewController<AVCaptureMetadataOutputObjectsDelegate>

- (id)init:(QRCodeBlock)block;
@property (assign,nonatomic) QRCodeBlock qrBlock;
@end
