//
//  OSETNativeAdViewCreator.h
//  YhsADSProject
//
//  Created by Shens on 11/7/2025.
//

#import <Foundation/Foundation.h>
#import <WindMillSDK/WindMillSDK.h>

#import <OSETSDK/OSETSDK.h>

@protocol OSETNativeAdViewCreatorDelegate <NSObject>

@optional
/**
 广告曝光回调
 */
- (void)OSETNativeAdViewCreatorWillExpose:(OSETNativeAdRenderer *)renderer;

/**
 广告点击回调
 */
- (void)OSETNativeAdViewCreatorDidClick:(OSETNativeAdRenderer *)renderer;

/**
 广告关闭回调
 */
- (void)OSETNativeAdViewCreatorDidClose:(OSETNativeAdRenderer *)renderer;

/**
 广告详情页关闭回调
 */
- (void)OSETNativeAdViewCreatorDetailViewClosed:(OSETNativeAdRenderer *)renderer;

@end
NS_ASSUME_NONNULL_BEGIN
@interface OSETNativeAdViewCreator : NSObject<AWMMediatedNativeAdViewCreator>

@property (nonatomic, weak) id<OSETNativeAdViewCreatorDelegate> delegate;

- (instancetype)initWithExpressAd:(OSETNativeAd *)nativeAd adView:(OSETBaseView *)adView;
- (instancetype)initWithNativeDataAdAd:(OSETNativeDataAd *)nativeDataAd adData:(OSETNativeDataAdObject *)adData;

@end

NS_ASSUME_NONNULL_END
