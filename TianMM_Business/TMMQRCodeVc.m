//
//  TMMQRCodeVcViewController.m
//  TianMM
//
//  Created by cocoa on 15/9/24.
//  Copyright © 2015年 cocoa. All rights reserved.
//

#import "TMMQRCodeVc.h"
#import "TMMCouponView.h"

static const char *kScanQRCodeQueueName = "ScanQRCodeQueue";

#define QR_VIEW_WIDTH   kScreen_Width/2-150
#define QR_VIEW_HEIGHT   kScreen_Height/2-150

@interface TMMQRCodeVc ()
{
    int num;
    BOOL upOrdown;
    NSTimer * timer;
}
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, assign) UIImageView * line;
@property (nonatomic, assign) TMMCouponView *couponView;
@property (nonatomic, assign) UIButton *qrCodeBn;
@property (nonatomic, assign) UIButton *codeBn;
@property (nonatomic) BOOL b_capture;


@end

@implementation TMMQRCodeVc

- (id)init:(QRCodeBlock)block{
    self = [super init];
    if (self) {
        _qrBlock=Block_copy(block);

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor colorWithRed:49/255.0f green:49/255.0f blue:49/255.0f alpha:1]];

    UIButton *exitBn = [UIButton buttonWithType:UIButtonTypeCustom];
    [exitBn setFrame:CGRectMake(0, 0, 100, 100)];
    [exitBn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [self.view addSubview:exitBn];

    exitBn.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return [RACSignal empty];
    }];
    [exitBn.rac_command release];
    
    _qrCodeBn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_qrCodeBn setFrame:CGRectMake(0, 0, 100, 100)];
    [_qrCodeBn setImage:[UIImage imageNamed:@"qrCode_normal"] forState:UIControlStateNormal];
    [_qrCodeBn setImage:[UIImage imageNamed:@"qrCode"] forState:UIControlStateSelected];
    [_qrCodeBn setSelected:YES];
    [self.view addSubview:_qrCodeBn];
    
    _qrCodeBn.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        if (!_b_capture) {
            [_codeBn setSelected:NO];
            [_qrCodeBn setSelected:YES];
            if (_couponView) {
                [_couponView removeFromSuperview];
                _couponView = nil;
            }
            [self startReading];
        }
        
        return [RACSignal empty];
    }];
    [_qrCodeBn.rac_command release];
    
    _codeBn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_codeBn setImage:[UIImage imageNamed:@"code_normal"] forState:UIControlStateNormal];
    [_codeBn setImage:[UIImage imageNamed:@"code"] forState:UIControlStateSelected];
    [_codeBn setFrame:CGRectMake(0, 0, 100, 100)];
    [self.view addSubview:_codeBn];
    
    _codeBn.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        if (_b_capture) {
            [_codeBn setSelected:YES];
            [_qrCodeBn setSelected:NO];
            [self stopReading];
            _couponView = [[TMMCouponView alloc]initWithFrame:CGRectMake(0, 0, kScreen_Width-30, kScreen_Height/2)];
            [_couponView SetBlock:^(NSString *CouponCode) {
                [self reportScanResult:CouponCode];
            }];

            [self.view addSubview:_couponView];
            [_couponView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.center.mas_equalTo(self.view);
                make.size.mas_equalTo(CGSizeMake(kScreen_Width-30, kScreen_Height/2 ));
            }];
        }
        return [RACSignal empty];
    }];
    [_codeBn.rac_command release];
    
    UIView* superView = self.view;
    [exitBn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(superView.mas_left).offset(25);
        make.top.mas_equalTo(superView.mas_top).offset(25);
    }];
    
    [_qrCodeBn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(superView.mas_centerX).offset(-kScreen_Width/4);
        make.bottom.mas_equalTo(superView.mas_bottom).offset(-20);
    }];
    
    [_codeBn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(superView.mas_centerX).offset(kScreen_Width/4);
        make.bottom.mas_equalTo(superView.mas_bottom).offset(-20);
    }];
    
    [self startReading];
}

-(void)animation
{
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(QR_VIEW_WIDTH, (QR_VIEW_HEIGHT)+2*num, 300, 2);
        if (2*num == 300) {
            upOrdown = YES;
        }
    }else {
        num --;
        _line.frame = CGRectMake(QR_VIEW_WIDTH, (QR_VIEW_HEIGHT)+2*num, 300, 2);
        if (num == 0) {
            upOrdown = NO;
        }
    }
}

- (BOOL)startReading
{
    NSError * error;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        DDLogInfo(@"%@", [error localizedDescription]);
        return NO;
    }
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create(kScanQRCodeQueueName, NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:CGRectMake(QR_VIEW_WIDTH, QR_VIEW_HEIGHT, 300, 300)];
    [self.view.layer addSublayer:_videoPreviewLayer];
    [_captureSession startRunning];
    [captureMetadataOutput release];
    
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(QR_VIEW_WIDTH, QR_VIEW_HEIGHT, 300, 2)];
    _line.image = [UIImage imageNamed:@"line.png"];
    [self.view addSubview:_line];
    [_line release];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animation) userInfo:nil repeats:YES];
    
    _b_capture = YES;
    
    return YES;
}

- (void)stopReading
{
    [timer invalidate];
    [_line removeFromSuperview];
    _line = nil;
    [_captureSession stopRunning];
    [_captureSession release];
    _captureSession = nil;
    [_videoPreviewLayer removeFromSuperlayer];
    [_videoPreviewLayer release];
    _videoPreviewLayer = nil;
    _b_capture = NO;
}

- (void)reportScanResult:(NSString *)result
{
    _qrBlock(result);
    if (_b_capture) {
        [self stopReading];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)systemLightSwitch:(BOOL)open
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        if (open) {
            [device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}

#pragma AVCaptureMetadataOutputObjectsDelegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
      fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        NSString *result;
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            result = metadataObj.stringValue;
        } else {
            DDLogDebug(@"不是二维码");
        }
        [self performSelectorOnMainThread:@selector(reportScanResult:) withObject:result waitUntilDone:NO];
    }
}

- (void)openSystemLight:(id)sender
{
    BOOL light = YES;
    if (light) {
        [self systemLightSwitch:YES];
    } else {
        [self systemLightSwitch:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc{
    [super dealloc];
    Block_release(_qrBlock);
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
