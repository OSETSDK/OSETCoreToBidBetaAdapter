//
//  OSETCustomToBidNativeAdData.h
//  OSETToBidDemo
//
//  Created by Shens on 18/12/2025.
//

#import <Foundation/Foundation.h>
#import <WindMillSDK/WindMillSDK.h>
@class OSETNativeDataAdObject;
NS_ASSUME_NONNULL_BEGIN

@interface OSETCustomToBidNativeAdData : NSObject<AWMMediatedNativeAdData>
- (instancetype)initWithAd:(OSETNativeDataAdObject *)ad;
@end

NS_ASSUME_NONNULL_END
