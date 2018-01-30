//
//  MLViewModel.m
//  MLTestDome
//
//  Created by 伟凯   刘 on 2018/1/30.
//  Copyright © 2018年 无敌小蚂蚱. All rights reserved.
//

#import "MLViewModel.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>

@interface MLViewModel()<AVAudioRecorderDelegate,SFSpeechRecognizerDelegate>
@property (nonatomic,strong) AVAudioRecorder * recorder;

@property (nonatomic,strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic,strong) AVAudioEngine *audioEngine;
@property (nonatomic,strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic,strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;

@end


@implementation MLViewModel

#pragma mark - lazyload
- (AVAudioEngine *)audioEngine{
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}
- (SFSpeechRecognizer *)speechRecognizer{
    if (!_speechRecognizer) {
        NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        _speechRecognizer =[[SFSpeechRecognizer alloc] initWithLocale:local];
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}

- (void)speechRecognitionAction_Perfect:(void(^)(BOOL perfect,NSString * msg))perfect{
    
    if ([SFSpeechRecognizer authorizationStatus] == SFSpeechRecognizerAuthorizationStatusAuthorized){
        
        [self starteRecording];
        perfect(YES,nil);
    }else{
        [SFSpeechRecognizer  requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (status) {
                    case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                        perfect(NO,@"App需要您的同意开启语音识别权限,才能使用语音识别技术");
                        break;
                    case SFSpeechRecognizerAuthorizationStatusDenied:

                        perfect(NO,@"App需要您的同意开启语音识别权限,才能使用语音识别技术");
                        break;
                    case SFSpeechRecognizerAuthorizationStatusRestricted:
                         perfect(NO,@"语音识别在这台设备上受到限制");
                        break;
                   
                    default:
                        break;
                }
                
            });
        }];
    }
}
- (void)shopspeechRecognitionAction{
    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
        if (_recognitionRequest) {
            [_recognitionRequest endAudio];
        }
    }
}
- (void)starteRecording{

    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    NSParameterAssert(!error);
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    NSParameterAssert(!error);
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    NSParameterAssert(!error);
    
    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    NSAssert(inputNode, @"录入设备没有准备好");
    NSAssert(_recognitionRequest, @"请求初始化失败");
    _recognitionRequest.shouldReportPartialResults = YES;
    __weak typeof(self) weakSelf = self;
    _recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:_recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BOOL isFinal = NO;
        if (result) {
            //            strongSelf.resultStringLable.text = result.bestTranscription.formattedString;
            [strongSelf.delegate identifyResults:result.bestTranscription.formattedString];
            isFinal = result.isFinal;
        }
        if (error || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            [strongSelf.delegate identifyFinish];
            strongSelf.recognitionTask = nil;
            strongSelf.recognitionRequest = nil;
        }
        
    }];
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    //在添加tap之前先移除上一个  不然有可能报"Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio',"之类的错误
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.recognitionRequest) {
            [strongSelf.recognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    NSParameterAssert(!error);
}
- (void)addImage_lacol:(BOOL)lacol chooseImage:(BOOL)chooseImage perfect:(void(^)(BOOL perfect,UIImagePickerController * PickerController,NSString * msg))perfect{
    
    UIImagePickerController * pickerController = [[UIImagePickerController alloc] init];
    
    if (chooseImage){
        
        pickerController.mediaTypes = @[(NSString *)kUTTypeImage];//只允许照片
        
    }else{
        
        pickerController.mediaTypes =@[(NSString*)kUTTypeMovie];//只允许视频
        
        pickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    }
    
    pickerController.allowsEditing = NO;
    
    if (lacol){//本地
        
        pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        perfect(YES,pickerController,nil);
        
    }else{//拍摄
        //拍摄时打开闪光灯（UIImagePickerControllerCameraFlashMode）
        //        UIImagePickerControllerCameraFlashModeOff
        //        UIImagePickerControllerCameraFlashModeAuto 默认自动
        //        UIImagePickerControllerCameraFlashModeOn
        //        pickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        //拍摄时打开的摄像头（UIImagePickerControllerCameraDevice）
        //        UIImagePickerControllerCameraDeviceRear,//后摄像头 默认
        //        UIImagePickerControllerCameraDeviceFront //前摄像头
        //        pickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        
        pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        AVAuthorizationStatus auth = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        if (auth == AVAuthorizationStatusAuthorized){
            perfect(YES,pickerController,nil);
        }else{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted){
                        perfect(YES,pickerController,nil);
                    }else{
                        NSString * msg = @"请在设置-隐私-相机选项中，允许访问你的相机。";
                       perfect(NO,nil,msg);
                        
                    }
                });
            }];
        }
 
    }

}
- (AVAudioRecorder *)recorder{
    if (!_recorder){
        //    AVAudioSession * session = [AVAudioSession sharedInstance];
        NSError * error = nil;
        //录音设置
        NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc]init];
        //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
        //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
        [recordSetting setValue:[NSNumber numberWithFloat:8000] forKey:AVSampleRateKey];
        //录音通道数  1 或 2
        [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
        //线性采样位数  8、16、24、32
        [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        //录音的质量
        //    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
        [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityMedium] forKey:AVEncoderAudioQualityKey];
        
        NSString *strUrl = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@.caf", strUrl,[self getCurrentTime]]];
        //初始化
        _recorder = [[AVAudioRecorder alloc]initWithURL:url settings:recordSetting error:&error];
        //开启音量检测
        _recorder.meteringEnabled = YES;
        _recorder.delegate = self;
    }
    return _recorder;
}

- (void)recordingBegin:(void(^)(BOOL perfect,NSString * msg))perfect{
    AVAudioSessionRecordPermission permission = [[AVAudioSession sharedInstance] recordPermission];
    if (permission == AVAudioSessionRecordPermissionGranted){
        if ([self.recorder prepareToRecord]) {
            if([self.recorder record]){
                perfect(YES,nil);
            }else{
                perfect(NO,@"录音功能开启失败咯");
            }
        }else{
            perfect(NO,@"录音功能开启失败咯");
        }
    }else{
        __weak typeof(self) weakSelf = self;
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (granted){
                // 通过验证
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([weakSelf.recorder prepareToRecord]) {
                        if([weakSelf.recorder record]){
                            perfect(YES,nil);
                        }else{
                            perfect(NO,@"录音功能开启失败咯");
                        }
                    }else{
                        perfect(NO,@"录音功能开启失败咯");
                    }
                });
                
            } else {
                // 未通过验证
                dispatch_async(dispatch_get_main_queue(), ^{
                     perfect(NO,@"App需要您开启录音权限之后才可以开启录音功能");
                });
            }
        }];
    }
    
}
- (void)recordingEndWithSuccessRecord:(void(^)(NSURL * url))block {
    
    __weak typeof(self) weakSelf = self;
    if (self.recorder) {
        [self.recorder stop];
        if (block) {
            //此时的录音为caf格式 需要转换成MP3格式  推荐lame第三方转换
            block(weakSelf.recorder.url);
        }
    }
}

//获取当地时间
- (NSString *)getCurrentTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmssS"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    return dateTime;
}
@end
