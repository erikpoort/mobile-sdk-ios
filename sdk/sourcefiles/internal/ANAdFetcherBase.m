/*   Copyright 2019 APPNEXUS INC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ANAdFetcherBase+PrivateMethods.h"
#import "ANUniversalTagRequestBuilder.h"
#import "ANSDKSettings+PrivateMethods.h"
#import "ANLogging.h"
#import "ANGlobal.h"
#import "ANStandardAd.h"
#import "ANRTBVideoAd.h"
#import "ANCSMVideoAd.h"
#import "ANSSMStandardAd.h"
#import "ANNativeStandardAdResponse.h"
#import "ANMediatedAd.h"
#import "ANNativeMediatedAdController.h"
#import "ANTrackerInfo.h"
#import "ANTrackerManager.h"
#import "NSTimer+ANCategory.h"
#import "ANUniversalTagAdServerResponse.h"
#import "ANAdView+PrivateMethods.h"
#import "ANGDPRSettings.h"
#import "ANHTTPNetworkSession.h"
#import "ANMultiAdRequest+PrivateMethods.h"

#pragma mark -

@interface ANAdFetcherBase()

@end




#pragma mark -

@implementation ANAdFetcherBase

#pragma mark Lifecycle.

- (nonnull instancetype)init
{
    self = [super init];
    if (!self)  { return nil; }
    
    return  self;
}

- (nonnull instancetype)initWithDelegate:(nonnull id)delegate andAdUnitMultiAdRequestManager:(nonnull ANMultiAdRequest *)adunitMARManager
{
    self = [self init];
    if (!self)  { return nil; }
    
    //
    self.delegate = delegate;
    self.adunitMARManager = adunitMARManager;
    return  self;
}
- (nonnull instancetype)initWithMultiAdRequestManager: (nonnull ANMultiAdRequest *)marManager
{
    self = [self init];
    if (!self)  { return nil; }
    
    //
    self.fetcherMARManager = marManager;
    
    return  self;
}

- (void)cookieSync:(NSHTTPURLResponse *)response
{
    if([ANGDPRSettings canAccessDeviceData] && !ANSDKSettings.sharedInstance.doNotTrack){
        NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:[response URL]];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:[response URL] mainDocumentURL:nil];
    }
    
}

-(void) stopAdLoad{
    self.isFetcherLoading = NO;
    self.ads = nil;
    
}
-(void)requestFailedWithError:(NSString *)error{
    NSError  *sessionError  = nil;
    if (self.fetcherMARManager) {
        sessionError = ANError(@"multi_ad_request_failed %@", ANAdResponseCode.NETWORK_ERROR.code,  error);
        [self.fetcherMARManager internalMultiAdRequestDidFailWithError:sessionError];
    }else{
        sessionError = ANError(@"ad_request_failed %@", ANAdResponseCode.NETWORK_ERROR.code, error);
        ANAdFetcherResponse *response = [ANAdFetcherResponse responseWithError:sessionError];
        [self processFinalResponse:response];
    }
    ANLogError(@"%@", sessionError);
}

- (void)requestAd
{
    if (self.isFetcherLoading)  { return; }
    
    NSMutableURLRequest  *request    = nil;
    
    if (self.fetcherMARManager) {
        request = [[ANUniversalTagRequestBuilder buildRequestWithMultiAdRequestManager:self.fetcherMARManager] mutableCopy];
    } else if (self.adunitMARManager) {
        request = [[ANUniversalTagRequestBuilder buildRequestWithAdFetcherDelegate:self.delegate adunitMultiAdRequestManager:self.adunitMARManager] mutableCopy];
    } else {
        request = [[ANUniversalTagRequestBuilder buildRequestWithAdFetcherDelegate:self.delegate] mutableCopy];
    }
    
    
    if (!request){
        [self requestFailedWithError:@"request is nil."];
        return;
    }
    
    
    [ANGlobal setANCookieToRequest:request];
    
    if(ANSDKSettings.sharedInstance.enableTestMode){
        [request setValue:@"1" forHTTPHeaderField:@"X-Is-Test"];
    }
    
    NSString  *requestContent  = [NSString stringWithFormat:@"%@ /n %@", [request URL],[[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] ];
    
    ANPostNotifications(kANUniversalAdFetcherWillRequestAdNotification, self,
                        @{kANUniversalAdFetcherAdRequestURLKey: requestContent});
    
    __weak __typeof__(self) weakSelf = self;
    [ANHTTPNetworkSession startTaskWithHttpRequest:request responseHandler:^(NSData * _Nonnull data, NSHTTPURLResponse * _Nonnull response) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (!strongSelf)  {
            ANLogError(@"COULD NOT ACQUIRE strongSelf.");
            return;
        }
        
        if (!strongSelf.fetcherMARManager) {
            [strongSelf restartAutoRefreshTimer];
        }
        strongSelf.isFetcherLoading = YES;
        [strongSelf cookieSync:response];
        NSString *responseString = [[NSString alloc] initWithData:data
                                                         encoding:NSUTF8StringEncoding];
        if (! strongSelf.fetcherMARManager) {
            ANLogDebug(@"Response JSON (for single tag requests ONLY)... %@", responseString);
        }
        
        ANPostNotifications(kANUniversalAdFetcherDidReceiveResponseNotification, strongSelf,
                            @{kANUniversalAdFetcherAdResponseKey: (responseString ? responseString : @"")});
        
        [strongSelf handleAdServerResponse:data];
        
    } errorHandler:^(NSError * _Nonnull error) {
        NSError  *sessionError  = nil;
        __typeof__(self) strongSelf = weakSelf;
        
        if (!strongSelf)  {
            ANLogError(@"COULD NOT ACQUIRE strongSelf.");
            return;
        }
        
        strongSelf.isFetcherLoading = NO;
        
        if (!strongSelf.fetcherMARManager) {
            [strongSelf restartAutoRefreshTimer];
        }
        
        [strongSelf requestFailedWithError:error.localizedDescription];
        ANLogError(@"%@", sessionError);
    }];
}




#pragma mark - Response processing methods.

/**
 * Start with raw data from a UT Response.
 * Transform the data into an array of dictionaries representing UT Response tags.
 *
 * If the fetcher is called by an ad unit, the process the tag with the existing fetcher.
 * If the fetcher is called in Multi-Ad Request Mode, then process each tag with fetcher from the ad unit that generated the tag.
 */
- (void)handleAdServerResponse:(NSData *)data
{
    NSArray<NSDictionary *>  *arrayOfTags  = [ANUniversalTagAdServerResponse generateTagsFromResponseData:data];
    
    if (!self.fetcherMARManager)
    {
        // If the UT Response is for a single adunit only, there should only be one ad object.
        //
        if (arrayOfTags.count > 1) {
            ANLogWarn(@"UT Response contains MORE THAN ONE TAG (%@).  Using FIRST TAG ONLY and ignoring the rest...", @(arrayOfTags.count));
        }
        
        [self prepareForWaterfallWithAdServerResponseTag:[arrayOfTags firstObject]];
        
        return;
        
    } else {
        [self handleAdServerResponseForMultiAdRequest:arrayOfTags];
    }
}

- (void)handleAdServerResponseForMultiAdRequest:(NSArray<NSDictionary *> *)arrayOfTags
{
    // Multi-Ad Request Mode.
    //
    if (arrayOfTags.count <= 0)
    {
        NSError  *responseError  = ANError(@"multi_ad_request_failed %@", ANAdResponseCode.UNABLE_TO_FILL.code, @"UT Response FAILED to return any ad objects.");
        
        [self.fetcherMARManager internalMultiAdRequestDidFailWithError:responseError];
        return;
    }
    
    [self.fetcherMARManager internalMultiAdRequestDidComplete];
    
    // Process each ad object in turn, matching with adunit via UUID.
    //
    if (self.fetcherMARManager.countOfAdUnits != [arrayOfTags count]) {
        ANLogWarn(@"Number of tags in UT Response (%@) DOES NOT MATCH number of ad units in MAR instance (%@).",
                  @([arrayOfTags count]), @(self.fetcherMARManager.countOfAdUnits));
    }
    
    for (NSDictionary<NSString *, id> *tag in arrayOfTags)
    {
        NSString  *uuid     = tag[kANUniversalTagAdServerResponseKeyTagUUID];
        id<ANMultiAdProtocol> adunit   = [self.fetcherMARManager internalGetAdUnitByUUID:uuid];
        
        if (!adunit) {
            ANLogWarn(@"UT Response tag UUID DOES NOT MATCH any ad unit in MAR instance.  Ignoring this tag...  (%@)", uuid);
            
        } else {
            [adunit ingestAdResponseTag:tag];
        }
    }
}


/**
 * Accept a single tag from an UT Response.
 * Divide the tag into ad objects and begin to process them via the waterfall.
 */
- (void)prepareForWaterfallWithAdServerResponseTag: (NSDictionary<NSString *, id> *)tag
{
    if (!tag) {
        ANLogError(@"tag is nil.");
        [self finishRequestWithError:ANError(@"response_no_ads", ANAdResponseCode.UNABLE_TO_FILL.code) andAdResponseInfo:nil];
        return;
    }
    
    if (tag[kANUniversalTagAdServerResponseKeyNoBid])
    {
        BOOL  noBid  = [tag[kANUniversalTagAdServerResponseKeyNoBid] boolValue];
        
        if (noBid) {
            ANLogWarn(@"response_no_ads");
            
            //
            ANAdResponseInfo *adResponseInfo = [[ANAdResponseInfo alloc] init];
            
            NSString *placementId  = @"";
            NSString *auctionId  = @"";
            if(tag[kANUniversalTagAdServerResponseKeyAdsTagId] != nil)
            {
                placementId = [NSString stringWithFormat:@"%@",tag[kANUniversalTagAdServerResponseKeyAdsTagId]];
            }
            
            if(tag[kANUniversalTagAdServerResponseKeyAdsAuctionId] != nil)
            {
                auctionId = [NSString stringWithFormat:@"%@",tag[kANUniversalTagAdServerResponseKeyAdsAuctionId]];
            }
                      
            adResponseInfo.placementId = placementId;
            adResponseInfo.auctionId = auctionId;

            [self finishRequestWithError:ANError(@"response_no_ads", ANAdResponseCode.UNABLE_TO_FILL.code) andAdResponseInfo:adResponseInfo];
            return;
        }
    }
    
    //
    NSMutableArray<id>  *ads            = [ANUniversalTagAdServerResponse generateAdObjectInstanceFromJSONAdServerResponseTag:tag];
    NSString            *noAdURLString  = tag[kANUniversalTagAdServerResponseKeyTagNoAdUrl];
    
    if (ads.count <= 0)
    {
        ANLogWarn(@"response_no_ads");
        [self finishRequestWithError:ANError(@"response_no_ads", ANAdResponseCode.UNABLE_TO_FILL.code) andAdResponseInfo:nil];
        return;
    }
    
    if (noAdURLString) {
        self.noAdUrl = noAdURLString;
    }
    
    //
    [self beginWaterfallWithAdObjects:ads];
}

- (void) beginWaterfallWithAdObjects:(nonnull NSMutableArray<id> *)ads
{
    self.ads = ads;
    
    [self clearMediationController];
    [self continueWaterfall:ANAdResponseCode.UNABLE_TO_FILL];
}


- (void)fireResponseURL:(nullable NSString *)urlString
                 reason:(nonnull ANAdResponseCode *)reason
               adObject:(nonnull id)adObject
{
    if (urlString) {
        [ANTrackerManager fireTrackerURL:urlString];
    }
    
    if (reason.code == ANAdResponseCode.SUCCESS.code) {
        ANAdFetcherResponse *response = [ANAdFetcherResponse responseWithAdObject:adObject andAdObjectHandler:self.adObjectHandler];
        [self processFinalResponse:response];
        
    } else {
        ANLogError(@"FAILED with reason=%@.", reason.message);
        
        // mediated ad failed. clear mediation controller
        [self clearMediationController];
        
        // stop waterfall if delegate reference (adview) was lost
        if (!self.delegate) {
            self.isFetcherLoading = NO;
            return;
        }

        [self continueWaterfall:reason];
    }
}

- (void)finishRequestWithResponseCode:(ANAdResponseCode *)reason
{
    ANLogError(@"%@", reason.message);
    [self finishRequestWithError:ANError(reason.message, reason.code, nil) andAdResponseInfo:nil];
}

@end
