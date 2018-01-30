//
//  ViewController.m
//  MLTestDome
//
//  Created by 伟凯   刘 on 2018/1/30.
//  Copyright © 2018年 无敌小蚂蚱. All rights reserved.
//

#import "ViewController.h"
#import "MLViewModel.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,strong)MLViewModel * viewModel;
@property (nonatomic,assign)BOOL lacol;
@property (weak, nonatomic) IBOutlet UIButton *mlBtn;
@end

@implementation ViewController

- (MLViewModel *)viewModel{
    if (!_viewModel){
        _viewModel = [[MLViewModel alloc] init];
    }
    return _viewModel;
}

- (void)viewDidLoad {
    [super viewDidLoad];

}
- (IBAction)showBtnAction:(id)sender {
    if ([self.mlBtn.titleLabel.text isEqualToString:@"完成"]){
        [self.mlBtn setTitle:@"MLShow" forState:UIControlStateNormal];
        [self.viewModel recordingEndWithSuccessRecord:^( NSURL *url) {
            
            NSLog(@"录音的地址 = %@",url.path);
        }];
        return;
    }
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"求求您选一个" message:@"🤕" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction * addImageAction = [UIAlertAction actionWithTitle:@"添加图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self addMultimediaAction_chooseImage:YES];
    }];
    UIAlertAction * addVideoAction = [UIAlertAction actionWithTitle:@"添加视频" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self addMultimediaAction_chooseImage:NO];
    }];
    __weak typeof(self) weakSelf = self;
    UIAlertAction * addVoiceAction = [UIAlertAction actionWithTitle:@"添加录音" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.viewModel recordingBegin:^(BOOL perfect, NSString *msg) {
            if (perfect){
                
                [weakSelf.mlBtn setTitle:@"完成" forState:UIControlStateNormal];
                
            }else{
                [weakSelf showAlertControllerStyleAlert_code:msg];

                [weakSelf.mlBtn setTitle:@"MLShow" forState:UIControlStateNormal];
            }
        }];
        
        
    }];
    
    UIAlertAction * cancalAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alertController addAction:addImageAction];
    [alertController addAction:addVideoAction];
    [alertController addAction:addVoiceAction];
    [alertController addAction:cancalAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)addMultimediaAction_chooseImage:(BOOL)chooseImage{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"求求您选一个" message:@"🤕" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction * localAction = [UIAlertAction actionWithTitle:@"本地" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.lacol = YES;
        [self showPickerVC:YES chooseImage:chooseImage];
        
    }];
    UIAlertAction * cameraAction = [UIAlertAction actionWithTitle:@"拍摄" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (![UIImagePickerController
                          isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) return;
        
        self.lacol = NO;
        [self showPickerVC:NO chooseImage:chooseImage];
        
    }];
    
    UIAlertAction * cancalAction = [UIAlertAction actionWithTitle:@"我放弃了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alertController addAction:localAction];
    [alertController addAction:cameraAction];
    [alertController addAction:cancalAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showPickerVC:(BOOL)lacol chooseImage:(BOOL)chooseImage {
    __weak typeof(self) weakSelf = self;
    [self.viewModel addImage_lacol:lacol chooseImage:chooseImage perfect:^(BOOL perfect, UIImagePickerController *PickerController, NSString *msg) {
        if (perfect){
            PickerController.delegate = weakSelf;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf presentViewController:PickerController animated:YES completion:nil];
            });
        }else{
             [weakSelf showAlertControllerStyleAlert_code:msg];
        }
    }];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {

    NSLog(@"%@", info);
    //相册返回的数据
    //    UIImagePickerControllerEditedImage // 编辑后的UIImage
    //    UIImagePickerControllerMediaType // 返回媒体的媒体类型
    //    UIImagePickerControllerOriginalImage // 原始的UIImage
    //    UIImagePickerControllerReferenceURL // 图片地址
    //本地视频返回的数据
    //    UIImagePickerControllerMediaType
    //    UIImagePickerControllerMediaURL
    //    UIImagePickerControllerReferenceURL
    //拍摄视频返回的数据
    //    UIImagePickerControllerMediaType
    //    UIImagePickerControllerMediaURL
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    if([mediaType isEqualToString:(NSString*)kUTTypeMovie]){
        
        NSURL *URL = info[UIImagePickerControllerMediaURL];
        
        NSData *file = [NSData dataWithContentsOfURL:URL];//视频data数据
        
        //如果想要获取视频的封面图 可以从视频中获取一张图片
        
        NSLog(@"获取到的视频 == %@",file);
        if (self.lacol){
            UISaveVideoAtPathToSavedPhotosAlbum(URL.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
        
        
    }else{
        
        UIImage * image = info[UIImagePickerControllerOriginalImage];//获取得到的原始图片
        NSLog(@"获取到的image == %@",image);
        if (self.lacol){
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
        
        
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error){
        [self showAlertControllerStyleAlert_code:@"图片保存失败"];
    }else{
        [self showAlertControllerStyleAlert_code:@"图片保存成功"];
    }
}
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    if (error) {
        [self showAlertControllerStyleAlert_code:@"保存视频失败"];
    }
    else {
        [self showAlertControllerStyleAlert_code:@"保存视频成功"];
    }
}
- (void)showAlertControllerStyleAlert_code:(NSString *)code{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"提示" message:code preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction * okAction = [UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
