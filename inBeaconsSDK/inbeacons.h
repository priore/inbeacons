//
//  inbeacons.h
//  http://www.inbeacons.com
//
//  Created by Danilo Priore on 06/02/15.
//  GitHub: https://github.com/priore
//
//  The MIT License (MIT)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
#import <Foundation/Foundation.h>

extern NSString *const inbeaconsTagResponseKey;
extern NSString *const inbeaconsTagProximityKey;
extern NSString *const inbeaconsTagFarKey;
extern NSString *const inbeaconsTagNearKey;
extern NSString *const inbeaconsTagImmediateKey;
extern NSString *const inbeaconsTagTokenKey;
extern NSString *const inbeaconsTagUuidKey;
extern NSString *const inbeaconsTagRegionKey;
extern NSString *const inbeaconsTagBeaconKey;
extern NSString *const inbeaconsTagPoiKey;
extern NSString *const inbeaconsTagRegionIDKey;
extern NSString *const inbeaconsTagRegionParentIDKey;
extern NSString *const inbeaconsTagLabelKey;
extern NSString *const inbeaconsTagEnterMessageRegionKey;
extern NSString *const inbeaconsTagExitMessageRegionKey;
extern NSString *const inbeaconsTagTitleKey;
extern NSString *const inbeaconsTagDescriptionKey;
extern NSString *const inbeaconsTagMediaKey;
extern NSString *const inbeaconsTagContentKey;
extern NSString *const inbeaconsTagActionKey;
extern NSString *const inbeaconsTagActionCodeKey;
extern NSString *const inbeaconsTagActionInfoKey;
extern NSString *const inbeaconsTagCampaignKey;
extern NSString *const inbeaconsTagBannerKey;
extern NSString *const inbeaconsTagURLKey;
extern NSString *const inbeaconsResponseOK;
extern NSString *const inbeaconsResponseYes;
extern NSString *const inbeaconsResponseNO;

extern NSString *const inbeaconsDidUserLoggedinNotification;
extern NSString *const inbeaconsDidEnterRegionNotification;
extern NSString *const inbeaconsDidExitRegionNotification;
extern NSString *const inbeaconsDidNearestBeaconNotification;
extern NSString *const inbeaconsDidFailWithErrorNotification;

@protocol inbeaconsDelegate;

@interface inbeacons : NSObject

@property (nonatomic, strong, readonly) NSString *username;
@property (nonatomic, strong, readonly) NSString *password;
@property (nonatomic, strong, readonly) NSString *token;

@property (nonatomic, assign, readonly) BOOL isEnteredRegion;

@property (nonatomic, assign) NSTimeInterval timeout;

@property (nonatomic, assign) id<inbeaconsDelegate> delegate;

+ (inbeacons*)sharedInstance;

// login to inbeacons.com services
- (void)loginWithUsername:(NSString*)username password:(NSString*)password;

// start/stop ibeacons monitoring
- (void)startMonitoring;
- (void)stopMonitoring;

@end

@protocol inbeaconsDelegate <NSObject>

@optional

- (void)inbeacons:(inbeacons*)inbeacon didUserLoggedin:(NSDictionary*)userInfo;
- (void)inbeacons:(inbeacons*)inbeacon didEnterRegion:(NSDictionary*)region;
- (void)inbeacons:(inbeacons*)inbeacon didExitRegion:(NSDictionary*)region;
- (void)inbeacons:(inbeacons*)inbeacon didNearestBeacon:(NSDictionary*)beacon proximity:(int)proximity;
- (void)inbeacons:(inbeacons*)inbeacon didFailWithError:(NSError*)error;

@end
