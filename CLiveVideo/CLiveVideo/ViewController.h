//
//  ViewController.h
//  CLiveVideo
//
//  Created by chuanliang on 16/2/25.
//  Copyright © 2016年 chuanliang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "x264Manager.h"

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureVideoDataOutput *avCaptureVideoDataOutput;
    
    UIView*             localView;
    
    x264Manager* manager264;
    
}

@property (nonatomic, retain) AVCaptureSession *avCaptureSession;

@end

