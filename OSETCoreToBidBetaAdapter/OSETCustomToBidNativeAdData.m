//
//  OSETCustomToBidNativeAdData.m
//  OSETToBidDemo
//
//  Created by Shens on 18/12/2025.
//

#import "OSETCustomToBidNativeAdData.h"
#import <OSETSDK/OSETSDK.h>
@interface OSETCustomToBidNativeAdData ()
@property (nonatomic, weak) OSETNativeDataAdObject *ad;
@end



@implementation OSETCustomToBidNativeAdData

@synthesize adMode = _adMode;
@synthesize callToAction = _callToAction;
@synthesize desc = _desc;
@synthesize iconUrl = _iconUrl;
@synthesize rating = _rating;
@synthesize title = _title;


@synthesize adType;
@synthesize networkId;
@synthesize videoCoverImage;
@synthesize imageUrlList;
@synthesize videoUrl;
@synthesize imageModelList;
@synthesize interactionType;

- (instancetype)initWithAd:(OSETNativeDataAdObject *)ad {
    self = [super init];
    if (self) {
        _ad = ad;
    }
    return self;
}
- (NSString *)title {
    if(self.ad.title && self.ad.title.length >0){
        return self.ad.title;
    }else if(self.ad.appName && self.ad.appName.length >0){
        return self.ad.appName;
    }else
    {
        return @"";
    }
}
- (NSString *)desc {
    return self.ad.desc;
}
- (NSString *)iconUrl {
    return self.ad.appIconUrl;
}
- (NSString *)appName {
    return self.ad.appName;
}
- (NSString *)callToAction {
    if (!_callToAction) {
        _callToAction = self.ad.buttonText;
    }
    return _callToAction;
}
- (double)rating {
    return 0;
}
- (AWMMediatedNativeAdMode)adMode {
    if (_adMode > 0) return _adMode;
    if(self.ad.isVideoAd){
        _adMode = AWMMediatedNativeAdModeVideo;
    }else{
        _adMode = AWMMediatedNativeAdModeLargeImage;
    }
    return _adMode;
}
- (void)dealloc {
//    WindmillLogDebug(@"%s", __func__);
}


@end
