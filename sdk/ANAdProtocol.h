/*   Copyright 2013 APPNEXUS INC
 
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ANAdFetcher;
@class ANLocation;

typedef enum _ANGender
{
    UNKNOWN,
    MALE,
    FEMALE
} ANGender;

// ANAdProtocol defines the properties and methods that are common to
// *all* ad types.  It can be understood as a toolkit for implementing
// ad types (It's used in the implementation of both banners and
// interstitials by the SDK).  If you wanted to, you could implement
// your own ad type using this protocol.

@protocol ANAdProtocol <NSObject>

@required
// An AppNexus placement ID.  A placement ID is a numeric ID that's
// associated with a place where ads can be shown.  In our
// implementations of banner and interstitial ad views, we associate
// each ad view with a placement ID.
@property (nonatomic, readwrite, strong) NSString *placementId;

// Represents the width and height of the ad view.  This should match
// the dimensions associated with the placement ID you're using.
@property (nonatomic, readwrite, assign) CGSize adSize;

// Determines whether the ad, when clicked, will open the device's
// native browser.
@property (nonatomic, readwrite, assign) BOOL opensInNativeBrowser;

// Each ad view is associated with an ad fetcher that does the work of
// actually requesting ads from the server.
@property (nonatomic, readwrite, strong) ANAdFetcher *adFetcher;

// Whether the ad view should display PSAs if there are no ads
// available from the server.
@property (nonatomic, readwrite, assign) BOOL shouldServePublicServiceAnnouncements;

// The user's location.  See ANLocation.h in this directory for
// details.
@property (nonatomic, readwrite, strong) ANLocation *location;

// The reserve price is the minimum bid amount you'll accept to show
// an ad.  Use this with caution, as it can drastically reduce fill
// rates (i.e., you will make less money).
@property (nonatomic, readwrite, assign) CGFloat reserve;

// The user's age.  This can contain a numeric age, a birth year, or a
// hyphenated age range.  For example, "56", "1974", or "25-35".
@property (nonatomic, readwrite, strong) NSString *age;

// The user's gender.  See the _ANGENDER struct above for details.
@property (nonatomic, readwrite, assign) ANGender gender;

// Used to pass custom keywords across different mobile ad server and
// SDK integrations.
@property (nonatomic, readwrite, strong) NSMutableDictionary *customKeywords;

- (NSString *)adType;
- (void)setLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude
                      timestamp:(NSDate *)timestamp horizontalAccuracy:(CGFloat)horizontalAccuracy;
- (void)addCustomKeywordWithKey:(NSString *)key value:(NSString *)value;
- (void)removeCustomKeywordWithKey:(NSString *)key;

#pragma mark Deprecated Properties

// This property is deprecated; use opensInNativeBrowser instead.
@property (nonatomic, readwrite, assign) BOOL clickShouldOpenInBrowser DEPRECATED_ATTRIBUTE;

@end

@protocol ANAdDelegate <NSObject>

@optional
- (void)adDidReceiveAd:(id<ANAdProtocol>)ad;
- (void)ad:(id<ANAdProtocol>)ad requestFailedWithError:(NSError *)error;
- (void)adWasClicked:(id<ANAdProtocol>)ad;
- (void)adWillClose:(id<ANAdProtocol>)ad;
- (void)adDidClose:(id<ANAdProtocol>)ad;
- (void)adWillPresent:(id<ANAdProtocol>)ad;
- (void)adDidPresent:(id<ANAdProtocol>)ad;
- (void)adWillLeaveApplication:(id<ANAdProtocol>)ad;

@end
