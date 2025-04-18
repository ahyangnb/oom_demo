#import "NativeVapView.h"
#import "UIView+VAP.h"
#import "QGVAPWrapView.h"
#import <SDWebImage/SDWebImage.h>


@interface NativeVapView : NSObject <FlutterPlatformView, VAPWrapViewDelegate>

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable) args
                   mRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar;
- (UIView *)view;

@end


@implementation NativeVapViewFactory {
    NSObject <FlutterPluginRegistrar> *_registrar;
}

- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
    }
    return self;
}

- (NSObject <FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                     viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    return [[NativeVapView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args mRegistrar:_registrar];
}

- (NSObject <FlutterMessageCodec> *)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

@end

@implementation NativeVapView {
    UIView *_containerView;
    NSObject <FlutterPluginRegistrar> *_registrar;
    NSString *_key;
    QGVAPWrapView *_wrapView;
    FlutterResult _result;
    //播放中就是ture，其他状态false
    BOOL playStatus;
    NSDictionary *_vapInfo;
}

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args mRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    if (self == [super init]) {
        playStatus = false;
        _containerView = [[UIView alloc] init];
        _registrar = registrar;
        _key = args[@"key"];
        FlutterMethodChannel *channel = [FlutterMethodChannel
                                       methodChannelWithName:[NSString stringWithFormat:@"flutter_vap_controller_%@", _key]
                                       binaryMessenger:registrar.messenger];
        [registrar addMethodCallDelegate:self channel:channel];
    }
    return self;
}

#pragma mark --flutter调native回调

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    _result = result;
    NSLog(@"%@",call.method);
    if ([@"playPath" isEqualToString:call.method]) {
        [self playByPath:call.arguments[@"path"]
                 vapInfo:call.arguments[@"vapInfo"]
                    fill:call.arguments[@"fill"]];
    }
    else if ([@"playAsset" isEqualToString:call.method]) {
        NSString* assetPath = [_registrar lookupKeyForAsset:call.arguments[@"asset"]];
        NSString* path = [[NSBundle mainBundle] pathForResource:assetPath ofType:nil];
        [self playByPath:path vapInfo:call.arguments[@"vapInfo"] fill:call.arguments[@"fill"]];
    }
    else if ([@"stop" isEqualToString:call.method]) {
        [self closeAction];
    }
}

- (void)closeAction {
    if (_wrapView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_wrapView removeFromSuperview];
            _wrapView = nil;
        });
    }
    playStatus = false;
    /// 是info，不是view。
    _vapInfo = nil;
    NSLog(@"VapVideo ===> closeAction");
}

- (void)playByPath:(NSString *)path vapInfo:(NSString *)vapInfo fill:(NSString*)fill {
    NSLog(@"播放准备开始");
    //限制只能有一个视频在播放
    if (playStatus) {
        NSLog(@"正有视频在播放");
        NSDictionary *resultDic = @{@"status": @"failure", @"errorMsg": @"playing"};
        if(_result!=nil){
            _result(resultDic);
        }
        return;
    }
    
    // Clean up existing wrapView if any
    [self closeAction];
    
    NSLog(@"播放正常");
    NSData *vapInfoData = [vapInfo dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    _vapInfo = [NSJSONSerialization JSONObjectWithData:vapInfoData options:NSJSONReadingAllowFragments error:&error];
    
    CGRect rect = self.view.bounds;
    if(rect.size.width == 0 || rect.size.height == 0){
        rect = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
    }
    
    // Create new wrapView
    _wrapView = [[QGVAPWrapView alloc] initWithFrame:rect];
    _wrapView.center = self.view.center;
    if([fill isEqualToString:@"1"]){
        _wrapView.contentMode = QGVAPWrapViewContentModeAspectFill;
    }else{
        _wrapView.contentMode = QGVAPWrapViewContentModeAspectFit;
    }
    _wrapView.autoDestoryAfterFinish = YES;
    [self.view addSubview:_wrapView];
    [_wrapView playHWDMP4:path repeatCount:0 delegate:self];
}

#pragma mark VAPWrapViewDelegate--播放回调

- (void)vapWrap_viewDidStartPlayMP4:(VAPView *)container {
    playStatus = true;
    NSLog(@"播放开始");
}

- (void)vapWrap_viewDidFailPlayMP4:(NSError *)error {
    NSLog(@"播放 %@",error);
    NSDictionary *resultDic = @{@"status": @"failure", @"errorMsg": error.description};
    
    // Cleanup after failure
    [self closeAction];
    
    if(_result!=nil){
        _result(resultDic);
    }
}

- (void)vapWrap_viewDidStopPlayMP4:(NSInteger)lastFrameIndex view:(VAPView *)container {
    NSLog(@"播放停止");
    NSDictionary *resultDic = @{@"status": @"stop",@"lastFrameIndex":@(lastFrameIndex)};
    playStatus = false;
    
    // Cleanup after stop
    [self closeAction];
}

- (void)vapWrap_viewDidFinishPlayMP4:(NSInteger)totalFrameCount view:(VAPView *)container {
    NSLog(@"播放结束");
    NSDictionary *resultDic = @{@"status": @"complete"};
    
    // Cleanup after playback finished
    _vapInfo = nil;
    playStatus = false;
    
    // we've already set `_wrapView.autoDestoryAfterFinish = YES;` below.
    // Auto cleanup if needed
    if (_wrapView.autoDestoryAfterFinish) {
        [self closeAction];
    }
    
    if(_result!=nil){
        _result(resultDic);
    }
}

- (NSString *)vapWrapview_contentForVapTag:(NSString *)tag resource:(QGVAPSourceInfo *)info {
    if ([[_vapInfo allKeys] containsObject:tag] && _vapInfo[tag] != nil) {
        return _vapInfo[tag];
    }
    return @"";
}

- (void)vapWrapView_loadVapImageWithURL:(NSString *)urlStr context:(NSDictionary *)context completion:(VAPImageCompletionBlock)completionBlock {
    if (urlStr.length > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:urlStr]
                                                        options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL *_Nullable targetURL) {}                                         completed:^(UIImage *_Nullable image, NSData *_Nullable data, NSError *_Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL *_Nullable imageURL) {
                completionBlock(image, error, urlStr);
            }];
        });
    }else{
        completionBlock([UIImage imageNamed:@" "], [NSError errorWithDomain:@"图片获取失败" code:-999999 userInfo:@{}], urlStr);
    }
}

- (UIView *)view {
    return _containerView;
}

- (void)dealloc {
    // Ensure cleanup when view is deallocated
    [self closeAction];
}

@end
