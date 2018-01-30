//
//  MLViewModel.h
//  MLTestDome
//
//  Created by 伟凯   刘 on 2018/1/30.
//  Copyright © 2018年 无敌小蚂蚱. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MLViewModel : NSObject

- (void)addImage_lacol:(BOOL)lacol chooseImage:(BOOL)chooseImage perfect:(void(^)(BOOL perfect,UIImagePickerController * PickerController,NSString * msg))perfect;

- (void)recordingBegin:(void(^)(BOOL perfect,NSString * msg))perfect;

- (void)recordingEndWithSuccessRecord:(void(^)(NSURL * url))block;

@end
