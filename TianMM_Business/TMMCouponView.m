//
//  TMMCouponView.m
//  TianMM_Business
//
//  Created by cocoa on 15/12/3.
//  Copyright © 2015年 cocoa. All rights reserved.
//

#import "TMMCouponView.h"

@interface TMMCouponView()<UITextFieldDelegate>
@property(assign,nonatomic) UITextField *textField;
@end

@implementation TMMCouponView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self createView];
    }
    return  self;
}

- (void)SetBlock:(CouponCodeBlock)block
{
    _CCBlock=Block_copy(block);
}

- (void)createView{
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTouch:)];
    [self addGestureRecognizer:tap];
    
    [self setBackgroundColor:[UIColor whiteColor]];
    self.layer.cornerRadius = 5.0;
    
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 30, 100, 50)];
    _textField.layer.borderColor = [[UIColor colorWithRed:229 / 255.0 green:229 / 255.0 blue:229 / 255.0 alpha:1] CGColor];
    _textField.layer.borderWidth = 1.0f;
    _textField.keyboardType = UIKeyboardTypeNumberPad;
    _textField.textAlignment =  NSTextAlignmentCenter;
    _textField.placeholder = @"请输入觅劵号"; //默认显示的字
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.delegate = self;
    _textField.font = [UIFont systemFontOfSize: 20.0];
    [self addSubview: _textField];
    [_textField release];

    UIButton *confirmBn = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmBn.layer.cornerRadius = 5.0f;

    [confirmBn setBackgroundColor:[UIColor colorWithRed:80/255.0f green:168/255.0f blue:42/255.0f alpha:1]];
    [confirmBn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirmBn.titleLabel.font = [UIFont systemFontOfSize: 20.0];
    [confirmBn setTitle:@"确认使用" forState:UIControlStateNormal];
    [self addSubview:confirmBn];
    
    confirmBn.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        _CCBlock(_textField.text);
        return [RACSignal empty];
    }];
    [confirmBn.rac_command release];
    
    [_textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(self.mas_top).offset(self.frame.size.height /4 );
        make.size.mas_equalTo(CGSizeMake(self.frame.size.width - 30, 50));
    }];

    [confirmBn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mas_centerX);

        make.bottom.mas_equalTo(self.mas_bottom).offset(-30);
        make.size.mas_equalTo(CGSizeMake(self.frame.size.width/2, 50));
    }];
}

-(void)viewTouch:arg{
    if ([_textField isFirstResponder]) {
        [_textField resignFirstResponder];
    }
}

//-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
//    for (UIView *view in self.subviews) {
//        if (!view.hidden && view.alpha > 0 && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
//            return YES;
//    }
//    return NO;
//}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField text];
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789\b"];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([string rangeOfCharacterFromSet:[characterSet invertedSet]].location != NSNotFound) {
        return NO;
    }
    
    text = [text stringByReplacingCharactersInRange:range withString:string];
    text = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *newString = @"";
    while (text.length > 0) {
        NSString *subString = [text substringToIndex:MIN(text.length, 4)];
        newString = [newString stringByAppendingString:subString];
        if (subString.length == 4) {
            newString = [newString stringByAppendingString:@" "];
        }
        text = [text substringFromIndex:MIN(text.length, 4)];
    }
    
    newString = [newString stringByTrimmingCharactersInSet:[characterSet invertedSet]];
    
    if (newString.length >= 16) {
        return NO;
    }
    [textField setText:newString];
    return NO;
}

- (void)dealloc{
    [super dealloc];
    Block_release(_CCBlock);
}
@end
