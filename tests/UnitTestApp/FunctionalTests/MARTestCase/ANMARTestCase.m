/*
 *
 *    Copyright 2020 APPNEXUS INC
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

#import <XCTest/XCTest.h>
#import "ANMultiAdRequest.h"
#import "ANHTTPStubbingManager.h"
#import "ANNativeAdRequest.h"
#import "ANInterstitialAd.h"
#import "ANInstreamVideoAd.h"
#import "ANBannerAdView.h"
#import "ANSDKSettings+PrivateMethods.h"
#import "ANAdView+PrivateMethods.h"
#import "ANBannerAdView+ANTest.h"
#import "ANUniversalAdFetcher+ANTest.h"
#import "ANInterstitialAd+ANTest.h"
#import "ANNativeAdRequest+ANTest.h"
#import "ANInstreamVideoAd+Test.h"
#import "ANAdView+ANTest.h"





@interface ANMARTestCase : XCTestCase<ANMultiAdRequestDelegate, ANBannerAdViewDelegate , ANInterstitialAdDelegate , ANNativeAdRequestDelegate,ANNativeAdDelegate , ANInstreamVideoAdLoadDelegate, ANInstreamVideoAdPlayDelegate>{
    int rtbBannerAdUnitCount;
    int rtbLoadBannerAdUnitCount;
}

@property (nonatomic, readwrite, strong)            ANMultiAdRequest    *mar;

@property (nonatomic, readwrite, strong)  ANBannerAdView       *bannerAd1;
@property (nonatomic, readwrite, strong)  ANBannerAdView        *bannerAd2;

@property (nonatomic, readwrite)  BOOL  receiveAdSuccess;
@property (nonatomic, readwrite)  BOOL  receiveAdFailure;

@property (nonatomic, strong) XCTestExpectation *loadAdResponseReceivedExpectation;
@property (nonatomic, strong) XCTestExpectation *loadAdResponseFailedExpectation;

@property (strong, nonatomic) ANInterstitialAd *interstitialAd1;
@property (strong, nonatomic) ANInterstitialAd *interstitialAd2;

@property (nonatomic,readwrite,strong) ANNativeAdRequest *nativeAdRequest1;
@property (nonatomic,readwrite,strong) ANNativeAdResponse *nativeAdResponse1;
@property (nonatomic,readwrite,strong) ANNativeAdRequest *nativeAdRequest2;
@property (nonatomic,readwrite,strong) ANNativeAdResponse *nativeAdResponse2;

@property (strong, nonatomic)  ANInstreamVideoAd  *videoAd1;
@property (strong, nonatomic)  ANInstreamVideoAd  *videoAd2;

@property (nonatomic, readwrite)  NSInteger  totalAdCount;
@property (nonatomic, readwrite)  NSInteger  currentAdCount;

@end

@implementation ANMARTestCase

#pragma mark - Test lifecycle.

- (void)setUp {
    [super setUp];
    [self clearCountsAndExpectations];

    [[ANHTTPStubbingManager sharedStubbingManager] enable];
    [ANHTTPStubbingManager sharedStubbingManager].ignoreUnstubbedRequests = YES;
    [ANBannerAdView setDoNotResetAdUnitUUID:YES];
    [ANInterstitialAd setDoNotResetAdUnitUUID:YES];
    [ANNativeAdRequest setDoNotResetAdUnitUUID:YES];
    [ANInstreamVideoAd setDoNotResetAdUnitUUID:YES];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}



- (void)clearCountsAndExpectations
{
       [[ANHTTPStubbingManager sharedStubbingManager] disable];
       [[ANHTTPStubbingManager sharedStubbingManager] removeAllStubs];
       
       ANSDKSettings.sharedInstance.locationEnabledForCreative = NO;
       self.loadAdResponseReceivedExpectation = nil;
       self.loadAdResponseFailedExpectation = nil;
       
       self.bannerAd1 = nil;
       self.bannerAd2 = nil;
       self.interstitialAd1 = nil;
       self.interstitialAd2 = nil;
       self.videoAd1 = nil;
       self.videoAd2 = nil;
       self.nativeAdRequest1 = nil;
       self.nativeAdRequest2 = nil;
       self.mar = nil;

       [ANBannerAdView setDoNotResetAdUnitUUID:NO];
       [ANInterstitialAd setDoNotResetAdUnitUUID:NO];
       [ANNativeAdRequest setDoNotResetAdUnitUUID:NO];
       [ANInstreamVideoAd setDoNotResetAdUnitUUID:NO];
    for (UIView *additionalView in [[ANGlobal getKeyWindow].rootViewController.view subviews]){
        [additionalView removeFromSuperview];
    }
}


#pragma mark - Test methods.

- (void)testMARCombinationTwoRTBInterstitial {
    self.totalAdCount = 2;
    self.currentAdCount = 0;
    self.interstitialAd1 = [self setInterstitialAdUnit:@"16433875"];
    self.interstitialAd2 =  [self setInterstitialAdUnit:@"16433875"];
    self.interstitialAd1.delegate = self;
    self.interstitialAd2.delegate = self;
    
    
    self.interstitialAd1.utRequestUUIDString = @"1";
    self.interstitialAd2.utRequestUUIDString = @"2";
    
    
    [self stubRequestWithResponse:@"testMARCombinationTwoRTBInterstitial"];
    self.mar = [[ANMultiAdRequest alloc] initWithMemberId:10094 andDelegate:self];
    [self.mar addAdUnit:self.interstitialAd1];
    [self.mar addAdUnit:self.interstitialAd2];
    [self.mar load];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertInterstitialAd:self.interstitialAd2 withPlacement:@"16433875" andCreativeId:@"166843826"];
    [self assertInterstitialAd:self.interstitialAd1 withPlacement:@"16433875" andCreativeId:@"166843825"];
    
}

- (void)testMARCombinationTwoInterstitialRTBAndCSM {
    
    self.totalAdCount = 2;
    self.currentAdCount = 0;
    self.interstitialAd1 = [self setInterstitialAdUnit:@"16433875"];
    self.interstitialAd2 =  [self setInterstitialAdUnit:@"16433875"];
    self.interstitialAd1.delegate = self;
    self.interstitialAd2.delegate = self;
    self.interstitialAd1.utRequestUUIDString = @"1";
    self.interstitialAd2.utRequestUUIDString = @"2";
    
    [self stubRequestWithResponse:@"testMARCombinationTwoInterstitialRTBAndCSM"];
    self.mar = [[ANMultiAdRequest alloc] initWithMemberId:10094 andDelegate:self];
    [self.mar addAdUnit:self.interstitialAd1];
    [self.mar addAdUnit:self.interstitialAd2];
    [self.mar load];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertInterstitialAd:self.interstitialAd2 withPlacement:@"16433875" andCreativeId:@"166843826"];
    [self assertInterstitialAd:self.interstitialAd1 withPlacement:@"16433875" andCreativeId:@"166843825"];
    
}
- (void)testMARCombinationTwoRTBNative {
    
    self.totalAdCount = 2;
    self.currentAdCount = 0;
    self.nativeAdRequest1 = [self setNativeAdUnit:@"14790206"];
    self.nativeAdRequest2 =  [self setNativeAdUnit:@"14790206"];
    self.nativeAdRequest1.delegate = self;
    self.nativeAdRequest2.delegate = self;
    
    self.nativeAdRequest1.utRequestUUIDString = @"1";
    self.nativeAdRequest2.utRequestUUIDString = @"2";
    
    [self stubRequestWithResponse:@"testMARCombinationTwoRTBNative"];
    self.mar = [[ANMultiAdRequest alloc] initWithMemberId:10094 andDelegate:self];
    [self.mar addAdUnit:self.nativeAdRequest1];
    [self.mar addAdUnit:self.nativeAdRequest2];
    [self.mar load];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertNativeAd:self.nativeAdRequest2 response:self.nativeAdResponse2 withPlacement:@"14790206" andCreativeId:@"154506782"];
    [self assertNativeAd:self.nativeAdRequest1 response:self.nativeAdResponse1 withPlacement:@"14790206" andCreativeId:@"196441069"];
    
    
}


- (void)testMARCombinationTwoNativeRTBAndCSM {
    
    self.totalAdCount = 2;
    self.currentAdCount = 0;
    self.nativeAdRequest1 = [self setNativeAdUnit:@"17982237"];
    self.nativeAdRequest2 =  [self setNativeAdUnit:@"14790206"];
    self.nativeAdRequest1.delegate = self;
    self.nativeAdRequest2.delegate = self;
    self.nativeAdRequest1.utRequestUUIDString = @"1";
    self.nativeAdRequest2.utRequestUUIDString = @"2";
    
    [self stubRequestWithResponse:@"testMARCombinationTwoNativeRTBAndCSM"];
    self.mar = [[ANMultiAdRequest alloc] initWithMemberId:10094 andDelegate:self];
    [self.mar addAdUnit:self.nativeAdRequest1];
    [self.mar addAdUnit:self.nativeAdRequest2];
    [self.mar load];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertNativeAd:self.nativeAdRequest2 response:self.nativeAdResponse2 withPlacement:@"14790206" andCreativeId:@"154506782"];
    [self assertNativeAd:self.nativeAdRequest1 response:self.nativeAdResponse1 withPlacement:@"17982237" andCreativeId:@"196441069"];
    
    
}

#pragma mark - Test methods.

- (void)testMARCombinationTwoBannerRTBAndCSM {
    
    self.totalAdCount = 2;
    self.currentAdCount = 0;
    self.bannerAd1 = [self setBannerAdUnit:CGRectMake(0, 50, 320, 50) size:CGSizeMake(320, 50)placement:@"17982237"];
    self.bannerAd2 = [self setBannerAdUnit:CGRectMake(0, 150, 300, 250) size:CGSizeMake(300, 250)placement:@"17982237"];
    self.bannerAd1.delegate = self;
    self.bannerAd2.delegate = self;
    self.bannerAd1.utRequestUUIDString = @"1";
    self.bannerAd2.utRequestUUIDString = @"2";
    
    [self stubRequestWithResponse:@"testMARCombinationTwoBannerRTBAndCSM"];
    self.mar = [[ANMultiAdRequest alloc] initWithMemberId:10094 andDelegate:self];
    [self.mar addAdUnit:self.bannerAd1];
    [self.mar addAdUnit:self.bannerAd2];
    [self.mar load];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertBannerAd:self.bannerAd2 size:CGSizeMake(300,250) withPlacement:@"17982237" andCreativeId:@"166843001"];
    [self assertBannerAd:self.bannerAd1 size:CGSizeMake(320,50) withPlacement:@"17982237" andCreativeId:@"166843311"];
    
}


- (void)testMARCombinationTwoBannerCSMAndSSM {
    
    self.totalAdCount = 2;
    self.currentAdCount = 0;
    self.bannerAd1 = [self setBannerAdUnit:CGRectMake(0, 50, 320, 50) size:CGSizeMake(320, 50)placement:@"17982237"];
    self.bannerAd2 = [self setBannerAdUnit:CGRectMake(0, 150, 300, 250) size:CGSizeMake(300, 250)placement:@"17982237"];
    self.bannerAd1.delegate = self;
    self.bannerAd2.delegate = self;
    self.bannerAd1.utRequestUUIDString = @"1";
    self.bannerAd2.utRequestUUIDString = @"2";
    
    [self stubRequestWithResponse:@"testMARCombinationTwoBannerCSMAndSSM"];
    self.mar = [[ANMultiAdRequest alloc] initWithMemberId:10094 andDelegate:self];
    [self.mar addAdUnit:self.bannerAd1];
    [self.mar addAdUnit:self.bannerAd2];
    [self.mar load];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertBannerAd:self.bannerAd2 size:CGSizeMake(300,250) withPlacement:@"17982237" andCreativeId:@"166843001"];
    [self assertBannerAd:self.bannerAd1 size:CGSizeMake(320,50) withPlacement:@"17982237" andCreativeId:@"166843311"];
    
}




- (void)testMARCombinationTwoBannerRTBAndSSM {
    
    self.totalAdCount = 2;
    self.currentAdCount = 0;
    self.bannerAd1 = [self setBannerAdUnit:CGRectMake(0, 50, 320, 50) size:CGSizeMake(320, 50)placement:@"17982237"];
    self.bannerAd2 = [self setBannerAdUnit:CGRectMake(0, 150, 300, 250) size:CGSizeMake(300, 250)placement:@"17982237"];
    self.bannerAd1.delegate = self;
    self.bannerAd2.delegate = self;
    self.bannerAd1.utRequestUUIDString = @"1";
    self.bannerAd2.utRequestUUIDString = @"2";
    
    [self stubRequestWithResponse:@"testMARCombinationTwoBannerRTBAndSSM"];
    self.mar = [[ANMultiAdRequest alloc] initWithMemberId:10094 andDelegate:self];
    [self.mar addAdUnit:self.bannerAd1];
    [self.mar addAdUnit:self.bannerAd2];
    [self.mar load];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertBannerAd:self.bannerAd2 size:CGSizeMake(300,250) withPlacement:@"17982237" andCreativeId:@"166843001"];
    [self assertBannerAd:self.bannerAd1 size:CGSizeMake(320,50) withPlacement:@"17982237" andCreativeId:@"166843311"];
    
}


- (void)testMARCombinationTwoRTBBanner {
    
    self.totalAdCount = 2;
    self.currentAdCount = 0;
    self.bannerAd1 = [self setBannerAdUnit:CGRectMake(0, 50, 320, 50) size:CGSizeMake(320, 50)placement:@"17982237"];
    self.bannerAd2 = [self setBannerAdUnit:CGRectMake(0, 150, 300, 250) size:CGSizeMake(300, 250)placement:@"17982237"];
    self.bannerAd1.delegate = self;
    self.bannerAd2.delegate = self;
    self.bannerAd1.utRequestUUIDString = @"1";
    self.bannerAd2.utRequestUUIDString = @"2";
    
    [self stubRequestWithResponse:@"testMARCombinationTwoRTBBanner"];
    self.mar = [[ANMultiAdRequest alloc] initWithMemberId:10094 andDelegate:self];
    [self.mar addAdUnit:self.bannerAd1];
    [self.mar addAdUnit:self.bannerAd2];
    [self.mar load];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertBannerAd:self.bannerAd2 size:CGSizeMake(300,250) withPlacement:@"17982237" andCreativeId:@"166843001"];
    [self assertBannerAd:self.bannerAd1 size:CGSizeMake(320,50) withPlacement:@"17982237" andCreativeId:@"166843311"];
    
}


- (void)testMARCombinationTwoRTBVideo {
   
    self.totalAdCount = 2;
    self.currentAdCount = 0;
    self.videoAd1 = [self setInstreamVideoAdUnit:@"17982237"];
    self.videoAd2 = [self setInstreamVideoAdUnit:@"17982237"];
    self.videoAd1.loadDelegate = self;
    self.videoAd2.loadDelegate = self;
    
    [self stubRequestWithResponse:@"testMARCombinationTwoRTBVideo"];
    self.mar = [[ANMultiAdRequest alloc] initWithMemberId:10094 andDelegate:self];
    [self.mar addAdUnit:self.videoAd1];
    [self.mar addAdUnit:self.videoAd2];

    [self.mar load];
    self.videoAd1.utRequestUUIDString = @"1";
    self.videoAd2.utRequestUUIDString = @"2";

    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertVideoAd:self.videoAd1 withPlacement:@"17982237" andCreativeId:@"162035357"];
    [self assertVideoAd:self.videoAd2 withPlacement:@"17982237" andCreativeId:@"162035356"];
    
    
}




- (void)testMARCombinationTwoVideoRTBAndCSM {
    
    self.totalAdCount = 2;
    self.currentAdCount = 0;
    self.videoAd1 = [self setInstreamVideoAdUnit:@"17982237"];
    self.videoAd2 = [self setInstreamVideoAdUnit:@"17982237"];
    self.videoAd1.loadDelegate = self;
    self.videoAd2.loadDelegate = self;
    
    [self stubRequestWithResponse:@"testMARCombinationTwoVideoRTBAndCSM"];
    self.mar = [[ANMultiAdRequest alloc] initWithMemberId:10094 andDelegate:self];
    [self.mar addAdUnit:self.videoAd1];
    [self.mar addAdUnit:self.videoAd2];
    [self.mar load];
    self.videoAd1.utRequestUUIDString = @"1";
    self.videoAd2.utRequestUUIDString = @"2";

    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:4 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertVideoAd:self.videoAd1 withPlacement:@"17982237" andCreativeId:@"162035357"];
    [self assertVideoAd:self.videoAd2 withPlacement:@"17982237" andCreativeId:@"162035356"];
}


-(void)createAllMARCombination:(NSString *)stubFileName {
    self.bannerAd1 = [self setBannerAdUnit:CGRectMake(0, 50, 320, 50) size:CGSizeMake(320, 50)placement:@"17982237"];
    
    self.bannerAd1.delegate = self;
    self.interstitialAd1 = [self setInterstitialAdUnit:@"17982237"];
    self.interstitialAd1.delegate = self;
    self.nativeAdRequest1 = [self setNativeAdUnit:@"17982237"];
    self.nativeAdRequest1.delegate = self;
    self.videoAd1 = [self setInstreamVideoAdUnit:@"17982237"];
    self.videoAd1.loadDelegate = self;
    
    

    
    self.totalAdCount = 4;
    self.currentAdCount = 0;
    self.mar = [[ANMultiAdRequest alloc] initWithMemberId:10094 andDelegate:self];

    [self stubRequestWithResponse:stubFileName];
   
    [self.mar addAdUnit:self.bannerAd1];
    [self.mar addAdUnit:self.interstitialAd1];
    [self.mar addAdUnit:self.nativeAdRequest1];
    [self.mar addAdUnit:self.videoAd1];
  
    
    
    [self.mar load];
    self.bannerAd1.utRequestUUIDString = @"1";
    self.interstitialAd1.utRequestUUIDString = @"2";
    self.nativeAdRequest1.utRequestUUIDString = @"3";
    self.videoAd1.utRequestUUIDString = @"4";
          
      
}



-(void)assertAllMARCombination {
    [self assertBannerAd:self.bannerAd1 size:CGSizeMake(320,50) withPlacement:@"17982237" andCreativeId:@"166843311"];
    [self assertInterstitialAd:self.interstitialAd1 withPlacement:@"17982237" andCreativeId:@"166843825"];
    
    [self assertNativeAd:self.nativeAdRequest1 response:self.nativeAdResponse1 withPlacement:@"17982237" andCreativeId:@"196441069"];
    [self assertVideoAd:self.videoAd1 withPlacement:@"17982237" andCreativeId:@"162035357"];
}






-(void)testMARCombinationAllRTB{
    [self createAllMARCombination:@"testMARCombinationAllRTB"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
    
}

-(void)testMARCombinationAllCSM{
    [self createAllMARCombination:@"testMARCombinationAllCSM"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
    
}
-(void)testMARCombinationBannerCSMWithOtherRTB {
    
    [self createAllMARCombination:@"testMARCombinationBannerCSMWithOtherRTB"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
}

-(void)testMARCombinationInterstitialCSMWithOtherRTB{
    [self createAllMARCombination:@"testMARCombinationInterstitialCSMWithOtherRTB"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
}


-(void)testMARCombinationBannerAndInterstitialCSMWithOtherRTB{
    [self createAllMARCombination:@"testMARCombinationNativeCSMWithOtherRTB"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
}


-(void)testMARCombinationBannerAndNativeCSMWithOtherRTB{
    
    [self createAllMARCombination:@"testMARCombinationBannerAndNativeCSMWithOtherRTB"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
}

-(void)testMARCombinationNativeCSMWithOtherRTB{
    
    [self createAllMARCombination:@"testMARCombinationBannerAndInterstitialCSMWithOtherRTB"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
}



-(void)testMARCombinationVideoCSMWithOtherRTB{
    
    [self createAllMARCombination:@"testMARCombinationVideoCSMWithOtherRTB"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
    
}



-(void)testMARCombinationVideoAndBannerCSMWithOtherRTB{
    
    [self createAllMARCombination:@"testMARCombinationVideoCSMWithOtherRTB"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
    
}

-(void)testMARCombinationVideoAndInterstitialCSMWithOtherRTB{
    [self createAllMARCombination:@"testMARCombinationVideoAndInterstitialCSMWithOtherRTB"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
    
}

-(void)testMARCombinationVideoAndNativeCSMWithOtherRTB{
    [self createAllMARCombination:@"testMARCombinationVideoAndNativeCSMWithOtherRTB"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
    
}

-(void)testMARCombinationInterstitialAndNativeCSMWithOtherRTB{
    [self createAllMARCombination:@"testMARCombinationInterstitialAndNativeCSMWithOtherRTB"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];}


-(void)testMARCombinationBannerRTBWithOtherCSM{
    
    [self createAllMARCombination:@"testMARCombinationBannerRTBWithOtherCSM"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
    
}


-(void)testMARCombinationNativeRTBWithOtherCSM{
    [self createAllMARCombination:@"testMARCombinationNativeRTBWithOtherCSM"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];}


-(void)testMARCombinationVideoRTBWithOtherCSM{
    [self createAllMARCombination:@"testMARCombinationVideoRTBWithOtherCSM"];
    self.loadAdResponseReceivedExpectation = [self expectationWithDescription:@"Waiting for adDidReceiveAd to be received"];
    [self waitForExpectationsWithTimeout:2 * kAppNexusRequestTimeoutInterval
                                 handler:^(NSError *error) {
        
    }];
    XCTAssertTrue(self.receiveAdSuccess);
    XCTAssertFalse(self.receiveAdFailure);
    [self assertAllMARCombination];
    
}


- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [self clearCountsAndExpectations];
}



#pragma mark - ANAdDelegate

- (void)adDidReceiveAd:(id<ANAdProtocol>)ad
{
    self.currentAdCount += 1;
    if(self.currentAdCount == self.totalAdCount){
        self.receiveAdSuccess = true;
        [self.loadAdResponseReceivedExpectation fulfill];
    }
}


- (void)ad:(id<ANAdProtocol>)ad requestFailedWithError:(NSError *)error
{
    self.receiveAdFailure = true;
    [self.loadAdResponseReceivedExpectation fulfill];
}



- (void)adRequest:(ANNativeAdRequest *)request didFailToLoadWithError:(NSError *)error {
    self.receiveAdFailure = true;
    [self.loadAdResponseReceivedExpectation fulfill];
    
}


- (void)adDidComplete:(nonnull id<ANAdProtocol>)ad withState:(ANInstreamVideoPlaybackStateType)state {
    
}


- (void)adRequest:(ANNativeAdRequest *)request didReceiveResponse:(ANNativeAdResponse *)response {
    self.currentAdCount += 1;
    if(self.currentAdCount == self.totalAdCount){
        self.receiveAdSuccess = true;
        [self.loadAdResponseReceivedExpectation fulfill];
    }
    
}


#pragma mark - Stubbing

- (void) stubRequestWithResponse:(NSString *)responseName {
    NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
    NSString *baseResponse = [NSString stringWithContentsOfFile: [currentBundle pathForResource:responseName
                                                                                         ofType:@"json" ]
                                                       encoding: NSUTF8StringEncoding
                                                          error: nil ];
    
    ANURLConnectionStub  *requestStub  = [[ANURLConnectionStub alloc] init];
    
    requestStub.requestURL    = [[[ANSDKSettings sharedInstance] baseUrlConfig] utAdRequestBaseUrl];
    requestStub.responseCode  = 200;
    requestStub.responseBody  = baseResponse;
    
    [[ANHTTPStubbingManager sharedStubbingManager] addStub:requestStub];
}

- (void)fulfillExpectation:(XCTestExpectation *)expectation
{
    [expectation fulfill];
}

- (void)waitForTimeInterval:(NSTimeInterval)delay
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"wait"];
    [self performSelector:@selector(fulfillExpectation:) withObject:expectation afterDelay:delay];
    
    [self waitForExpectationsWithTimeout:delay + 1 handler:nil];
}


// Assert Ad Response

-(void)assertBannerAd:(ANBannerAdView *)ad size:(CGSize )size withPlacement:(NSString *)placement andCreativeId:(NSString *)creativeId {
    XCTAssertEqual(ad.frame.size.width, size.width);
    XCTAssertEqual(ad.frame.size.height, size.height);
    XCTAssertEqual(ad.adType, ANAdTypeBanner);
    XCTAssertEqualObjects(ad.creativeId, creativeId);
    XCTAssertEqualObjects(ad.placementId, placement);
}

-(void)assertInterstitialAd:(ANInterstitialAd *)ad withPlacement:(NSString *)placement andCreativeId:(NSString *)creativeId {
    XCTAssertEqualObjects(ad.creativeId, creativeId);
    XCTAssertEqualObjects(ad.placementId, placement);
}


-(void)assertNativeAd:(ANNativeAdRequest *)request response:(ANNativeAdResponse *)response withPlacement:(NSString *)placement andCreativeId:(NSString *)creativeId {
    if(response != nil){
        XCTAssertEqualObjects(response.creativeId, creativeId);
    }
    XCTAssertEqualObjects(request.placementId, placement);
}

-(void)assertVideoAd:(ANInstreamVideoAd *)ad withPlacement:(NSString *)placement andCreativeId:(NSString *)creativeId {
    if(ad.creativeId != nil){
        XCTAssertEqualObjects(ad.creativeId, creativeId);
    }
    XCTAssertEqualObjects(ad.placementId, placement);
}

//Ad Request Builder

-(ANNativeAdRequest *) setNativeAdUnit : (NSString *)placement {
    ANNativeAdRequest *nativeAdRequest= [[ANNativeAdRequest alloc] init];
    nativeAdRequest.placementId = placement;
    nativeAdRequest.shouldLoadIconImage = YES;
    nativeAdRequest.shouldLoadMainImage = YES;
    return nativeAdRequest;
}

-(ANBannerAdView *) setBannerAdUnit:(CGRect)rect  size:(CGSize )size placement:(NSString *)placement  {
    ANBannerAdView* bannerAdView = [[ANBannerAdView alloc] initWithFrame:rect
                                                             placementId:placement
                                                                  adSize:size];
    bannerAdView.rootViewController = [ANGlobal getKeyWindow].rootViewController;
    [[ANGlobal getKeyWindow].rootViewController.view addSubview:bannerAdView];
    return bannerAdView;
}

-(ANInterstitialAd *) setInterstitialAdUnit: (NSString *)placement  {
    ANInterstitialAd *interstitialAd = [[ANInterstitialAd alloc] initWithPlacementId:placement];
    return interstitialAd;
}


-(ANInstreamVideoAd *) setInstreamVideoAdUnit: (NSString *)placement  {
    ANInstreamVideoAd* instreamVideoAdUnit = [[ANInstreamVideoAd alloc] initWithPlacementId:placement];
    return instreamVideoAdUnit;
}
@end
