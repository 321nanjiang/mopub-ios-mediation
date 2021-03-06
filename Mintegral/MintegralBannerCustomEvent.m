#import "MintegralBannerCustomEvent.h"
#import <MTGSDK/MTGSDK.h>
#import "MintegralAdapterConfiguration.h"
#import <MTGSDKBanner/MTGBannerAdView.h>
#import <MTGSDKBanner/MTGBannerAdViewDelegate.h>
#if __has_include(<MoPubSDKFramework/MoPub.h>)
    #import <MoPubSDKFramework/MoPub.h>
#elif __has_include(<MoPub/MoPub.h>)
    #import <MoPub/MoPub.h>
#else
    #import "MoPub.h"
#endif
#if __has_include(<MoPubSDKFramework/MPLogging.h>)
    #import <MoPubSDKFramework/MPLogging.h>
#elif __has_include(<MoPub/MoPub.h>)
    #import <MoPub/MPLogging.h>
#else
    #import "MPLogging.h"
#endif

typedef enum {
    MintegralErrorBannerParaUnresolveable = 19,
    MintegralErrorBannerCamPaignListEmpty,
} MintegralBannerErrorCode;

@interface MintegralBannerCustomEvent() <MTGBannerAdViewDelegate>

@property(nonatomic,strong) MTGBannerAdView *bannerAdView;
@property (nonatomic, copy) NSString *mintegralAdUnitId;
@property (nonatomic, copy) NSString *adPlacementId;
@property (nonatomic, copy) NSString *adm;
@end

@implementation MintegralBannerCustomEvent
@dynamic delegate;
@dynamic localExtras;

- (void)requestAdWithSize:(CGSize)size adapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {    
    NSString *appId = [info objectForKey:@"appId"];
    NSString *appKey = [info objectForKey:@"appKey"];
    NSString *unitId = [info objectForKey:@"unitId"];
    NSString *placementId = [info objectForKey:@"placementId"];
    
    NSString *errorMsg = nil;
    
    if (!appId) errorMsg = [errorMsg stringByAppendingString: @"Invalid or missing Mintegral appId. Failing ad request. Ensure the app ID is valid on the MoPub dashboard."];
    if (!appKey) errorMsg = [errorMsg stringByAppendingString: @"Invalid or missing Mintegral appKey. Failing ad request. Ensure the app key is valid on the MoPub dashboard."];
    if (!unitId) errorMsg = [errorMsg stringByAppendingString: @"Invalid or missing Mintegral unitId. Failing ad request. Ensure the unit ID is valid on the MoPub dashboard."];
    
    if (errorMsg) {
        NSError *error = [NSError errorWithDomain:kMintegralErrorDomain code:MintegralErrorBannerParaUnresolveable userInfo:@{NSLocalizedDescriptionKey : errorMsg}];
        
        if ([self.description respondsToSelector:@selector(inlineAdAdapter:didFailToLoadAdWithError:)]) {
            MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], nil);
            [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:error];
        }
        return;
    }
    
    self.adm = adMarkup;
    self.mintegralAdUnitId = unitId;
    self.adPlacementId = placementId;
    
    
    [MintegralAdapterConfiguration initializeMintegral:info setAppID:appId appKey:appKey];
    
    UIViewController *vc =  [UIApplication sharedApplication].keyWindow.rootViewController;
    _bannerAdView = [[MTGBannerAdView alloc] initBannerAdViewWithAdSize:size placementId:placementId unitId:unitId rootViewController:vc];
    _bannerAdView.delegate = self;
    
    if (self.adm) {
        MPLogInfo(@"Loading Mintegral banner ad markup for Advanced Bidding");
        [_bannerAdView loadBannerAdWithBidToken:self.adm];
    } else {
        MPLogInfo(@"Loading Mintegral banner ad");
        [_bannerAdView loadBannerAd];
    }
    
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class) dspCreativeId:nil dspName:nil], self.mintegralAdUnitId);
}

#pragma mark -- MTGBannerAdViewDelegate
- (void)adViewLoadSuccess:(MTGBannerAdView *)adView {
    if ([self.delegate respondsToSelector:@selector(inlineAdAdapter:didLoadAdWithAdView:)]) {
        MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)], self.mintegralAdUnitId);
        MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)], self.mintegralAdUnitId);
        MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], self.mintegralAdUnitId);
        [self.delegate inlineAdAdapter:self didLoadAdWithAdView:adView];
    }
}

- (void)adViewLoadFailedWithError:(NSError *)error adView:(MTGBannerAdView *)adView {
    if ([self.delegate respondsToSelector:@selector(inlineAdAdapter:didFailToLoadAdWithError:)]) {
        MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], nil);
        [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:error];
    }
}

- (void)adViewWillLogImpression:(MTGBannerAdView *)adView {
    if ([self.delegate respondsToSelector:@selector(inlineAdAdapterDidTrackImpression:)]) {
        [self.delegate inlineAdAdapterDidTrackImpression:self];
    }
}

- (void)adViewDidClicked:(MTGBannerAdView *)adView {
    if ([self.delegate respondsToSelector:@selector(trackClick)]) {
        MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], self.mintegralAdUnitId);
        [self.delegate inlineAdAdapterDidTrackClick:self];
    }
}

- (void)adViewWillLeaveApplication:(MTGBannerAdView *)adView {
    if ([self.delegate respondsToSelector:@selector(adWillLeaveApplicationForAdapter:)]) {
        MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)], self.mintegralAdUnitId);
        [self.delegate inlineAdAdapterWillLeaveApplication:self];
    }
}

- (void)adViewWillOpenFullScreen:(MTGBannerAdView *)adView {
    MPLogAdEvent([MPLogEvent adWillLeaveApplicationForAdapter:NSStringFromClass(self.class)], self.mintegralAdUnitId);
}

- (void)adViewCloseFullScreen:(MTGBannerAdView *)adView {
    MPLogAdEvent([MPLogEvent adDidDismissModalForAdapter:NSStringFromClass(self.class)], self.mintegralAdUnitId);
}

- (void)adViewClosed:(MTGBannerAdView *)adView {
    MPLogInfo(@"adViewClosed for MTGBannerAdView");
}

#pragma mark - Turn off auto impression and click
- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return NO;
}

@end


