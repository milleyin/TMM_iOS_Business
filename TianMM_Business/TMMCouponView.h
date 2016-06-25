//
//  TMMCouponView.h
//  TianMM_Business
//
//  Created by cocoa on 15/12/3.
//  Copyright © 2015年 cocoa. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^CouponCodeBlock)(NSString *CouponCode);

@interface TMMCouponView : UIView
- (void)SetBlock:(CouponCodeBlock)block;

@property (assign,nonatomic) CouponCodeBlock CCBlock;
@end
