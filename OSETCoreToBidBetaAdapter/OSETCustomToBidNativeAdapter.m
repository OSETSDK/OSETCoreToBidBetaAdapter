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
@interface OSETCustomToBidNativeAdapter ()<OSETNativeAdDelegate,OSETNativeDataAdDelegate,OSETNativeAdViewCreatorDelegate>
@property (nonatomic, weak) id<AWMCustomNativeAdapterBridge> bridge;
@property (nonatomic,strong) OSETNativeAd *nativeAd;
@property (nonatomic,strong) OSETNativeDataAd *nativeDataAd;
@property (nonatomic, strong) NSArray<OSETNativeAd *> *nativeAdDataArray;

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
    // 获取特定键的值
    if([parameter.customInfo[@"isExpressAd"] boolValue] == YES){
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
    if (result.win) {
        WindmillLogDebug(@"OSET-WindWill-竞价成功", @"%@", NSStringFromSelector(_cmd));
    }else{
        WindmillLogDebug(@"OSET-WindWill-竞价失败", @"%@", NSStringFromSelector(_cmd));
    }
    self.nativeAdDataArray = nil;
}


/// 信息流加载成功
- (void)nativeDataAdLoadSuccessWithNative:(id)nativeDataAd nativeExpressViews:(NSArray<OSETNativeDataAdObject *> * _Nullable)nativeDataObjects{
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
    OSETNativeDataAdObject * adData = nativeDataObjects.firstObject;
    NSString *price = [NSString stringWithFormat:@"%ld",(long)adData.eCPM];
    [self.bridge nativeAd:self didAdServerResponseWithExt:@{
        AWMMediaAdLoadingExtECPM: price
    }];
    NSMutableArray *adArray = [[NSMutableArray alloc] init];
    AWMMediatedNativeAd *mNativeAd = [[AWMMediatedNativeAd alloc] init];
    mNativeAd.originMediatedNativeAd = adData;
    mNativeAd.data = [[OSETCustomToBidNativeAdData alloc]initWithAd:adData];
    OSETNativeAdViewCreator * creator = [[OSETNativeAdViewCreator alloc] initWithNativeDataAdAd:self.nativeDataAd adData:adData];
    creator.delegate = self;
    mNativeAd.viewCreator = creator;
    [adArray addObject:mNativeAd];
    [self.bridge nativeAd:self didLoadWithNativeAds:adArray];
}
/// 加载失败
/// @param nativeDataAd 信息流实例
/// @param error 错误信息
- (void)nativeDataAdFailedToLoad:(id)nativeDataAd error:(NSError *)error{
    
}


- (void)nativeExpressAdLoadSuccessWithNative:(id)native nativeExpressViews:(NSArray *)nativeExpressViews{
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
    OSETBaseView *adView = nativeExpressViews.firstObject;
    NSString *price = [NSString stringWithFormat:@"%ld",(long)adView.eCPM];
    [self.bridge nativeAd:self didAdServerResponseWithExt:@{
        AWMMediaAdLoadingExtECPM: price
    }];
    NSMutableArray *adArray = [[NSMutableArray alloc] init];
    self.nativeAd.delegate = self;
    AWMMediatedNativeAd *mNativeAd = [[AWMMediatedNativeAd alloc] init];
    mNativeAd.originMediatedNativeAd = adView;
    mNativeAd.viewCreator = [[OSETNativeAdViewCreator alloc] initWithExpressAd:self.nativeAd adView:adView];
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
