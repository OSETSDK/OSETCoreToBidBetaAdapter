//
//  OSETCustomToBidNativeAdapter.m
//  YhsADSProject
//
//  Created by Shens on 9/7/2025.
//

#import "OSETCustomToBidNativeAdapter.h"
#import "OSETNativeAdViewCreator.h"
#import <WindFoundation/WindFoundation.h>
#import "OSETCustomToBidNativeAdData.h"
#import <OSETSDK/OSETSDK.h>
#import "OSETToBidBiddingHelper.h"
@interface OSETCustomToBidNativeAdapter ()<OSETNativeAdDelegate,OSETNativeDataAdDelegate,OSETNativeAdViewCreatorDelegate>
@property (nonatomic, weak) id<AWMCustomNativeAdapterBridge> bridge;
@property (atomic,strong) OSETNativeAd *nativeAd;
@property (atomic,strong) OSETNativeDataAd *nativeDataAd;
@property (atomic, strong) id biddingAd;
@property (nonatomic, assign) BOOL isExpressAd;

@end

@implementation OSETCustomToBidNativeAdapter
- (instancetype)initWithBridge:(id<AWMCustomNativeAdapterBridge>)bridge {
    self = [super init];
    if (self) {
        _bridge = bridge;
    }
    return self;
}

- (void)loadAdWithPlacementId:(NSString *)placementId adSize:(CGSize)size parameter:(AWMParameter *)parameter {
    self.biddingAd = nil;
    self.isExpressAd = [parameter.customInfo[@"isExpressAd"] boolValue];
    // 获取特定键的值
    if (self.isExpressAd) {
        if(!self.nativeAd){
            self.nativeAd = [[OSETNativeAd alloc] initWithSlotId:placementId size:size rootViewController:nil];
            self.nativeAd.delegate = self;
            [self.nativeAd loadAdData];
        }else{
            self.nativeAd.delegate = self;
            [self.nativeAd loadAdData];
        }
       
    }else{
        if(!self.nativeDataAd){
            self.nativeDataAd = [[OSETNativeDataAd alloc]initWithSlotId:placementId size:size rootViewController:nil];
            self.nativeDataAd.delegate = self;
            [self.nativeDataAd loadAdData];
        }else{
            self.nativeDataAd.delegate = self;
            [self.nativeDataAd loadAdData];
        }
    }
}

- (BOOL)mediatedAdStatus {
    return YES;
}

- (void)didReceiveBidResult:(AWMMediaBidResult *)result {
    OSETToBidReportBidResult(self.biddingAd, result);
}


- (void)destory {
    self.nativeAd.delegate = nil;
    self.nativeDataAd.delegate = nil;
    self.nativeAd = nil;
    self.nativeDataAd = nil;
    self.biddingAd = nil;
}

/// 信息流加载成功
- (void)nativeDataAdLoadSuccessWithNative:(id)nativeDataAd nativeDataObjects:(NSArray<OSETNativeDataAdObject *> * _Nullable)nativeDataObjects{
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
    OSETNativeDataAd *loadedAd = self.nativeDataAd;
    if (self.isExpressAd || nativeDataAd != loadedAd || !loadedAd) {
        return;
    }
    OSETNativeDataAdObject *adData = [nativeDataObjects isKindOfClass:[NSArray class]]
        ? nativeDataObjects.firstObject : nil;
    if (![adData isKindOfClass:[OSETNativeDataAdObject class]]) {
        [self.bridge nativeAd:self didLoadFailWithError:[NSError errorWithDomain:@"OSETToBidAdapter"
            code:-1 userInfo:@{NSLocalizedDescriptionKey: @"OSET 自渲染信息流返回空广告"}]];
        return;
    }
    self.biddingAd = loadedAd;
    NSString *price = [NSString stringWithFormat:@"%ld",(long)adData.eCPM];
    [self.bridge nativeAd:self didAdServerResponseWithExt:@{
        WindMillConstant.ECPM : price
    }];
    if (self.biddingAd != loadedAd) {
        return;
    }
    NSMutableArray *adArray = [[NSMutableArray alloc] init];
    OSETNativeAdViewCreator * creator = [[OSETNativeAdViewCreator alloc] initWithNativeDataAdAd:loadedAd adData:adData];
    AWMMediatedNativeAd *mNativeAd = [[AWMMediatedNativeAd alloc] initWithData:[[OSETCustomToBidNativeAdData alloc]initWithAd:adData] viewCreator:creator originAd:adData];
    creator.delegate = self;
    [adArray addObject:mNativeAd];
    [self.bridge nativeAd:self didLoadWithNativeAds:adArray];
}
/// 加载失败
/// @param nativeDataAd 信息流实例
/// @param error 错误信息
- (void)nativeDataAdFailedToLoad:(id)nativeDataAd error:(NSError *)error{
    [self.bridge nativeAd:self didLoadFailWithError:error];
}


- (void)nativeExpressAdLoadSuccessWithNative:(id)native nativeExpressViews:(NSArray *)nativeExpressViews{
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
    OSETNativeAd *loadedAd = self.nativeAd;
    if (!self.isExpressAd || native != loadedAd || !loadedAd) {
        return;
    }
    OSETBaseView *adView = [nativeExpressViews isKindOfClass:[NSArray class]]
        ? nativeExpressViews.firstObject : nil;
    if (![adView isKindOfClass:[OSETBaseView class]]) {
        [self.bridge nativeAd:self didLoadFailWithError:[NSError errorWithDomain:@"OSETToBidAdapter"
            code:-1 userInfo:@{NSLocalizedDescriptionKey: @"OSET 模板信息流返回空广告或无效 View"}]];
        return;
    }
    // bridge 可能同步触发竞价结果，先保存当前广告 View。
    self.biddingAd = adView;
    NSString *price = [NSString stringWithFormat:@"%ld",(long)adView.eCPM];
    [self.bridge nativeAd:self didAdServerResponseWithExt:@{
        WindMillConstant.ECPM : price
    }];
    if (self.biddingAd != adView) {
        return;
    }
    NSMutableArray *adArray = [[NSMutableArray alloc] init];
    loadedAd.delegate = self;
    AWMMediatedNativeAd *mNativeAd = [[AWMMediatedNativeAd alloc] initWithData:nil viewCreator: [[OSETNativeAdViewCreator alloc] initWithExpressAd:loadedAd adView:adView] originAd:adView];
    mNativeAd.view = adView;
    [adArray addObject:mNativeAd];
    [self.bridge nativeAd:self didLoadWithNativeAds:adArray];
}

- (void)nativeExpressAdRenderSuccess:(id)nativeExpressView{
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
    if([nativeExpressView isKindOfClass:[UIView class]]){
        [self.bridge nativeAd:self renderSuccessWithExpressView:nativeExpressView];
    }else{
    }
}
- (void)nativeExpressAdFailedToLoad:(nonnull id)nativeExpressAd error:(nonnull NSError *)error {
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
    [self.bridge nativeAd:self didLoadFailWithError:error];

}
- (void)nativeExpressAdFailedToRender:(nonnull id)nativeExpressView {
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
    [self.bridge nativeAd:self renderFailWithExpressView:nativeExpressView andError:[NSError new]];

}
- (void)nativeExpressAdDidClick:(nonnull id)nativeExpressView {
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
    [self.bridge nativeAd:self didClickWithMediatedNativeAd:nativeExpressView];

}
- (void)nativeExpressAdDidClose:(nonnull id)nativeExpressView {
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
    [self.bridge nativeAd:self didClose:nativeExpressView closeReasons:@[]];
}

- (void)nativeExpressAdDidExposured:(id)nativeExpressView{
    if([nativeExpressView isKindOfClass:[UIView class]]){
        UIView * v = nativeExpressView;
        if(v.superview){
            CGRect r = v.superview.frame;
            v.superview.frame = CGRectMake(r.origin.x, r.origin.y, v.bounds.size.width, v.bounds.size.height);
        }
    }
    [self.bridge nativeAd:self didVisibleWithMediatedNativeAd:nativeExpressView];
}
/**
 广告曝光回调
 */
- (void)OSETNativeAdViewCreatorWillExpose:(OSETNativeAdRenderer *)renderer{
    [self.bridge nativeAd:self didVisibleWithMediatedNativeAd:renderer.dataObject];
}
/**
 广告点击回调
 */
- (void)OSETNativeAdViewCreatorDidClick:(OSETNativeAdRenderer *)renderer{
    [self.bridge nativeAd:self didClickWithMediatedNativeAd:renderer.dataObject];
}

/**
 广告关闭回调
 */
- (void)OSETNativeAdViewCreatorDidClose:(OSETNativeAdRenderer *)renderer{
    [self.bridge nativeAd:self didClose:renderer.dataObject closeReasons:@[]];
}

/**
 广告详情页关闭回调
 */
- (void)OSETNativeAdViewCreatorDetailViewClosed:(OSETNativeAdRenderer *)renderer{
    
}
-(void)dealloc{
//    NSLog(@"dealloc ====  %@",self);
}
@end
