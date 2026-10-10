#ifndef OSETToBidBiddingHelper_h
#define OSETToBidBiddingHelper_h

#import <OSETSDK/OSETSDK.h>
#import <WindMillSDK/WindMillSDK.h>
#import <dispatch/dispatch.h>

// ToBid 与 OSET 的失败原因编码不同，不能直接透传枚举值。
static inline OSETBiddingFailureReason OSETToBidLossReason(TBReason reason) {
    switch (reason) {
        case TBReasonNone:
            return OSETBiddingFailureReasonUnknown;
        case TBReasonTimeout:
            return OSETBiddingFailureReasonTimeout;
        case TBReasonNoFill:
            return OSETBiddingFailureReasonNoFill;
        case TBReasonAboveBottomPrice:
        case TBReasonBidFailed:
            return OSETBiddingFailureReasonLowBid;
        case TBReasonCacheExpired:
            return OSETBiddingFailureReasonInvalidBid;
        case TBReasonBlockMaterial:
            return OSETBiddingFailureReasonCreativeRejected;
        case TBReasonBlockFrequencyControl:
        case TBReasonBlockCompetingProducts:
        case TBReasonOther:
        case TBReasonCustom:
        default:
            return OSETBiddingFailureReasonOther;
    }
}

// 仅由下面的安全入口调用。只读取上报所需字段，不透传 ext / 推荐模型。
static inline NSDictionary *OSETToBidBiddingInfo(AWMMediaBidResult *result, BOOL isWin) {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    NSMutableDictionary *extra = [NSMutableDictionary dictionaryWithDictionary:@{
        @"mediation": @"ToBid",
        @"win": @(isWin)
    }];
    if (isWin) {
        if ([result respondsToSelector:@selector(winnerPrice)]) {
            int64_t price = result.winnerPrice;
            if (price > 0) {
                info[OSETBiddingInfoBiddingPriceKey] = @(price);
            }
        }
    } else {
        OSETBiddingFailureReason lossReason = OSETBiddingFailureReasonUnknown;
        if ([result respondsToSelector:@selector(bidResult)]) {
            id model = result.bidResult;
            if ([model isKindOfClass:[TBBidResultModel class]] &&
                [model respondsToSelector:@selector(reason)]) {
                TBReason reason = [(TBBidResultModel *)model reason];
                lossReason = OSETToBidLossReason(reason);
                extra[@"reason"] = @(reason);
            }
        }
        info[OSETBiddingInfoLossReasonKey] = @(lossReason);
    }
    info[OSETBiddingInfoExtraKey] = [extra copy];
    return [info copy];
}

// 每次有效回调都转交 SDK；去重由 OSETSDK 内部处理。
// 异常时放弃本次上报，避免上报影响广告主流程。
static inline void OSETToBidReportBidResult(id ad, AWMMediaBidResult *result) {
    @try {
        if (![result isKindOfClass:[AWMMediaBidResult class]] ||
            ![result respondsToSelector:@selector(win)]) {
            return;
        }
        if (![ad isKindOfClass:[OSETBaseAd class]] &&
            ![ad isKindOfClass:[OSETBaseView class]]) {
            return;
        }
        // View / SDK 对象统一在主线程使用，避免后台回调直接访问它们。
        // block 强引用当前广告实例，不会在执行时改用下一次加载的新对象。
        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                OSETToBidReportBidResult(ad, result);
            });
            return;
        }
        BOOL isWin = result.win;
        SEL selector = isWin ? @selector(reportBiddingWinWithInfo:)
                             : @selector(reportBiddingLossWithInfo:);
        if (![ad respondsToSelector:selector]) {
            return;
        }
        NSDictionary *info = OSETToBidBiddingInfo(result, isWin);
        if (isWin) {
            [ad reportBiddingWinWithInfo:info];
        } else {
            [ad reportBiddingLossWithInfo:info];
        }
    } @catch (NSException *exception) {
        // 不在异常路径格式化未知对象或再次调用 SDK 日志。
        (void)exception;
    }
}

#endif
