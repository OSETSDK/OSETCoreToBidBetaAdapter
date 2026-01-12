//
//  OSETNativeAdViewCreator.m
//  YhsADSProject
//
//  Created by Shens on 11/7/2025.
//

#import "OSETNativeAdViewCreator.h"
#import <WindFoundation/WindFoundation.h>

@interface OSETNativeAdViewCreator()<OSETNativeAdRendererDelegate>
@property (nonatomic, strong) OSETBaseView *expressAdView;
@property (nonatomic, strong) OSETNativeAd *expressAd;
@property (nonatomic, strong) OSETNativeDataAd *expressDataAd;
@property (nonatomic, strong) OSETNativeAdRenderer *expressDataAdRender;
@property (nonatomic, strong) UIImage *image;
@end
@implementation OSETNativeAdViewCreator

@synthesize adLogoView = _adLogoView;
@synthesize dislikeBtn = _dislikeBtn;
@synthesize imageView = _imageView;
@synthesize imageViewArray = _imageViewArray;
@synthesize mediaView = _mediaView;
@synthesize interactiveView = _interactiveView;

- (instancetype)initWithExpressAd:(OSETNativeAd *)nativeAd adView:(OSETBaseView *)adView{
    self = [super init];
    if (self) {
        _expressAd  = nativeAd;
        _expressAdView = adView;
    }
    return self;
}
- (instancetype)initWithNativeDataAdAd:(OSETNativeDataAd *)nativeDataAd adData:(OSETNativeDataAdObject *)adData{
    self = [super init];
    if (self) {
        _expressDataAd  = nativeDataAd;
        OSETNativeAdRenderer * expressDataAdRenderer = [[OSETNativeAdRenderer alloc]init];
        expressDataAdRenderer.dataObject = adData;
        expressDataAdRenderer.delegate = self;
        _expressDataAdRender = expressDataAdRenderer;
    }
    return self;
}
- (void)setRootViewController:(UIViewController *)viewController {
    if(self.expressAd){
        self.expressAd.viewController = viewController;
    }
    if(self.expressDataAd){
        self.expressDataAd.viewController = viewController;
    }
    if(self.expressDataAdRender){
        self.expressDataAdRender.viewController = viewController;
    }
}
- (void)refreshData {

}

- (void)registerContainer:(UIView *)containerView withClickableViews:(NSArray<UIView *> *)clickableViews {
    [self.expressDataAdRender registerContainerView:containerView withDataObject:self.expressDataAdRender.dataObject];
    [self.expressDataAdRender registerClickableViews:clickableViews];
    [self.expressDataAdRender registerCloseView:self.dislikeBtn];
}
- (void)setPlaceholderImage:(UIImage *)placeholderImage {
    _image = placeholderImage;
}
#pragma mark - Getter
- (UIView *)adLogoView {
    if (!_adLogoView) {
        _adLogoView = [[UIImageView alloc]init];
        _adLogoView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
        _adLogoView.contentMode = UIViewContentModeScaleAspectFit;
        _adLogoView.layer.cornerRadius = 4;
        _adLogoView.layer.masksToBounds = YES;
        if(self.expressDataAdRender.dataObject.adIconUrl && self.expressDataAdRender.dataObject.adIconUrl.length > 0) {
            NSString *image = self.expressDataAdRender.dataObject.adIconUrl;
            NSURL *imgURL = [NSURL URLWithString:image];
            UIImageView * iv = (UIImageView *)_adLogoView;
            [iv sm_setImageWithURL:imgURL];
        }
    }
    return _adLogoView;
}
- (UIButton *)dislikeBtn {
    if (!_dislikeBtn) {
        _dislikeBtn = [[UIButton alloc]init];
//        [_dislikeBtn setTitle:@"X" forState:UIControlStateNormal];
    }
    return  _dislikeBtn;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        NSArray *imageAry = self.expressDataAdRender.dataObject.imageList;
        _imageView = [[UIImageView alloc] init];
        if(imageAry.count > 0) {
            NSString *image = imageAry.firstObject[@"url"];
            NSURL *imgURL = [NSURL URLWithString:image];
            [_imageView sm_setImageWithURL:imgURL placeholderImage:self.image];
        }
    }
    return _imageView;
}
- (NSArray<UIImageView *> *)imageViewArray {
    return @[];
}
- (UIView *)mediaView {
    return  self.expressDataAdRender.mediaView;
}
- (UIView *)interactiveView {
    if(self.expressDataAdRender.dataObject.isShake){
        if(self.expressDataAdRender.shakeView){
            return  self.expressDataAdRender.shakeView;
        }else{
            return [UIView new];
        }
    }else{
        return [UIView new];
    }
}
/**
 广告曝光回调
 */
- (void)OSETNativeAdRendererWillExpose:(OSETNativeAdRenderer *)renderer{
    if ([self.delegate respondsToSelector:@selector(OSETNativeAdViewCreatorWillExpose:)]) {
        [self.delegate OSETNativeAdViewCreatorWillExpose:renderer];
    }
}

/**
 广告点击回调
 */
- (void)OSETNativeAdRendererDidClick:(OSETNativeAdRenderer *)renderer{
    if ([self.delegate respondsToSelector:@selector(OSETNativeAdViewCreatorDidClick:)]) {
        [self.delegate OSETNativeAdViewCreatorDidClick:renderer];
    }

}
/**
 广告关闭回调
 */
- (void)OSETNativeAdRendererDidClose:(OSETNativeAdRenderer *)renderer{
    if ([self.delegate respondsToSelector:@selector(OSETNativeAdViewCreatorDidClose:)]) {
        [self.delegate OSETNativeAdViewCreatorDidClose:renderer];
    }
}
/**
 广告详情页关闭回调
 */
- (void)OSETNativeAdRendererDetailViewClosed:(OSETNativeAdRenderer *)renderer{
    if ([self.delegate respondsToSelector:@selector(OSETNativeAdViewCreatorDetailViewClosed:)]) {
        [self.delegate OSETNativeAdViewCreatorDetailViewClosed:renderer];
    }
}
- (void)dealloc {
    [self.expressDataAdRender unregisterDataObject];
    WindmillLogDebug(@"OSET", @"%s", __func__);
}

@end
