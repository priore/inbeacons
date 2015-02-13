//
//  inbeacons.m
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
#define inbeaconsBaseDomain @"http://www.inbeacons.com/api"

#define inbeaconsAPILoginKey            @"login"
#define inbeaconsAPIGetPlacesKey        @"get_places"
#define inbeaconsAPISetPlacesActionKey  @"set_place_action"
#define inbeaconsAPIGetRuleKey          @"get_rule"
#define inbeaconsAPIEnterRegionKey      @"enter"
#define inbeaconsAPIExitRegionKey       @"exit"

#ifdef DEBUG
#define INBLog(s, ...) NSLog(s, ##__VA_ARGS__)
#else
#define INBLog(s, ...)
#endif

#import "inbeacons.h"
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(int, inbeaconsAPI)
{
    inbeaconsNone,
    inbeaconsLogin,
    inbeaconsGetPlaces,
    inbeaconsGetRule,
    inbeaconsSetPlaceAction
};

typedef NS_ENUM(int, inbeaconsRegionActions)
{
    inbeaconsRegionActionEnterRegion = 1,
    inbeaconsRegionActionExitRegion
};

@interface inbeacons() <NSURLConnectionDelegate, NSURLConnectionDataDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSString *regionParentID;
@property (nonatomic, strong) NSDictionary *region;

@property (nonatomic, assign) long major;
@property (nonatomic, assign) long minor;

@property (nonatomic, assign) NSInteger statusCode;

@property (nonatomic, assign) inbeaconsAPI apiInvoked;
@property (nonatomic, assign) inbeaconsRegionActions regionActions;

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *webData;

@property (nonatomic, strong) CLBeacon *nearestBeacon;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) NSMutableDictionary *regions;
@property (nonatomic, strong) NSMutableDictionary *beacons;

@end

@implementation inbeacons

NSString *const inbeaconsTagResponseKey = @"result";
NSString *const inbeaconsTagProximityKey = @"proximity";
NSString *const inbeaconsTagFarKey = @"far";
NSString *const inbeaconsTagNearKey = @"near";
NSString *const inbeaconsTagImmediateKey = @"immediate";
NSString *const inbeaconsTagTokenKey = @"token";
NSString *const inbeaconsTagUuidKey = @"uuids";
NSString *const inbeaconsTagRegionKey = @"region";
NSString *const inbeaconsTagBeaconKey = @"beacon";
NSString *const inbeaconsTagPoiKey = @"poi";
NSString *const inbeaconsTagRegionIDKey = @"id";
NSString *const inbeaconsTagRegionParentIDKey = @"pid";
NSString *const inbeaconsTagLabelKey = @"label";
NSString *const inbeaconsTagEnterMessageRegionKey = @"entermessage";
NSString *const inbeaconsTagExitMessageRegionKey = @"exitmessage";
NSString *const inbeaconsTagTitleKey = @"title";
NSString *const inbeaconsTagDescriptionKey = @"description";
NSString *const inbeaconsTagMediaKey = @"media";
NSString *const inbeaconsTagContentKey = @"content";
NSString *const inbeaconsTagActionKey = @"action";
NSString *const inbeaconsTagActionCodeKey = @"code";
NSString *const inbeaconsTagActionInfoKey = @"info";
NSString *const inbeaconsTagCampaignKey = @"campaign";
NSString *const inbeaconsTagBannerKey = @"banner";
NSString *const inbeaconsTagURLKey = @"url";
NSString *const inbeaconsResponseOK = @"ok";
NSString *const inbeaconsResponseYes = @"Y";
NSString *const inbeaconsResponseNO = @"N";

NSString *const inbeaconsDidUserLoggedinNotification = @"inbeaconsDidUserLoggedinNotification";
NSString *const inbeaconsDidEnterRegionNotification = @"inbeaconsDidEnterRegionNotification";
NSString *const inbeaconsDidExitRegionNotification = @"inbeaconsDidExitRegionNotification";
NSString *const inbeaconsDidNearestBeaconNotification = @"inbeaconsDidNearestBeaconNotification";
NSString *const inbeaconsDidFailWithErrorNotification = @"inbeaconsDidFailWithErrorNotification";

+ (inbeacons*)sharedInstance
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = self.new;
    });
    return instance;
}


- (id)init
{
    if (self = [super init]) {
        
        self.timeout = 60;
        self.apiInvoked = inbeaconsNone;
        
        _isEnteredRegion = NO;
    }
    
    return self;
}

- (void)loginWithUsername:(NSString*)username password:(NSString*)password
{
    _username = username;
    _password = password;
    
    [self invokeAPI:inbeaconsLogin];
}

- (void)startMonitoring
{
    if (self.locationManager == nil)
        [self getPlacesWithToken:self.token];
}

- (void)stopMonitoring
{
    if (self.locationManager != nil) {
        [self.regions enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            CLBeaconRegion *region = [obj objectForKey:inbeaconsTagRegionKey];
            if (region != nil) {
                [self.locationManager stopRangingBeaconsInRegion:region];
                [self.locationManager stopMonitoringForRegion:region];
            }
        }];
        
        self.regions = nil;
        self.beacons = nil;
    }
}

#pragma mark - CLLocationManager Delegates

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    INBLog(@"Start monitoring region with id: %@", region.identifier);
    [self.locationManager requestStateForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (self.regions == nil || (self.regions && [self.regions objectForKey:region.identifier] == nil)) {
        INBLog(@"The region with id %@ not listed", region.identifier);
        return;
    }
    
    if (state == CLRegionStateInside) {
        INBLog(@"State for region with id %@: inside", region.identifier);
        
        if (!_isEnteredRegion) {
            [self setPlaceAction:inbeaconsRegionActionEnterRegion
                           token:self.token
                          region:[self.regions objectForKey:region.identifier]];
        }
        
    }
    else if (state == CLRegionStateOutside) {
        INBLog(@"State for region with id %@: outside", region.identifier);
        
        if (_isEnteredRegion) {
            [self setPlaceAction:inbeaconsRegionActionExitRegion
                           token:self.token
                          region:[self.regions objectForKey:region.identifier]];
        }
    }
    else {
        INBLog(@"State for region with id %@: unknown", region.identifier);

        NSDictionary *dict = [self.regions objectForKey:region.identifier];
        [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidExitRegionNotification object:dict];

        if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didExitRegion:)])
            [self.delegate inbeacons:self didExitRegion:dict];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    INBLog(@"Enter region with id: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    INBLog(@"Exit region with id: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    INBLog(@"Monitoring region %@ failed: %@", region.identifier, error);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidFailWithErrorNotification object:error];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didFailWithError:)])
        [self.delegate inbeacons:self didFailWithError:error];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    // non elabora altri beacons finche non ha finito il precedente
    if (beacons == nil || (beacons != nil && [beacons count]) == 0 || self.apiInvoked != inbeaconsNone)
        return;
    
    self.nearestBeacon = [beacons firstObject];
    NSString *key = [NSString stringWithFormat:@"%@_%@", self.nearestBeacon.major, self.nearestBeacon.minor];
    if ([self.beacons objectForKey:key] == nil) {
        NSDictionary *region_obj = [self.regions objectForKey:region.identifier];
        if (region_obj != nil) {
            [self getRuleWithToken:self.token
                              uuid:[region_obj objectForKey:inbeaconsTagUuidKey]
                             major:[self.nearestBeacon.major longValue]
                             minor:[self.nearestBeacon.minor longValue]];
        } else {
            [self checkProximityWithNearestBeacon:self.nearestBeacon key:key];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    INBLog(@"inbeacons error: %@", error);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidFailWithErrorNotification object:error];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didFailWithError:)])
        [self.delegate inbeacons:self didFailWithError:error];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied) {
        [self stopMonitoring];
    }
    else if (status == kCLAuthorizationStatusAuthorized) {
        [self startMonitoring];
    }
}

#pragma mark - Beacons

- (void)checkProximityWithNearestBeacon:(CLBeacon*)nearestBeacon key:(NSString*)key
{
    NSDictionary *beacon = [self.beacons objectForKey:key];
    if (beacon != nil && [[beacon objectForKey:inbeaconsTagResponseKey] isEqualToString:inbeaconsResponseOK]) {
        if ([[beacon objectForKey:inbeaconsTagProximityKey] isEqualToString:inbeaconsResponseNO]) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidNearestBeaconNotification object:@{inbeaconsTagBeaconKey : beacon, inbeaconsTagProximityKey : @((int)CLProximityUnknown)}];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didNearestBeacon:proximity:)])
                [self.delegate inbeacons:self didNearestBeacon:beacon proximity:(int)CLProximityUnknown];
            
        } else {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidNearestBeaconNotification object:@{inbeaconsTagBeaconKey : beacon, inbeaconsTagProximityKey : @((int)nearestBeacon.proximity)}];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didNearestBeacon:proximity:)])
                [self.delegate inbeacons:self didNearestBeacon:beacon proximity:(int)nearestBeacon.proximity];
        }
    } else {
        INBLog(@"There are no rules defined for this beacon");
    }
}

#pragma mark - Regions

- (void)startMonitoringForRegions:(NSDictionary*)regions
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusDenied) {
        NSString *msg = @"To use background location you must turn on 'Always' in the Location Services Settings";
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:kCLErrorDenied userInfo:@{ NSLocalizedDescriptionKey: msg}];
        [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidFailWithErrorNotification object:error];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didFailWithError:)])
            [self.delegate inbeacons:self didFailWithError:error];
        
        return;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
        NSAssert([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"], @"NSLocationAlwaysUsageDescription key not present in the info.plist. Please add it in order to recieve location updates");
#endif
    
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        [self.locationManager requestAlwaysAuthorization];
#endif
    
    self.regions = [NSMutableDictionary new];
    
    NSArray *pois = [regions objectForKey:inbeaconsTagPoiKey];
    [pois enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *region = [obj mutableCopy];
        NSString *region_id = [regions objectForKey:inbeaconsTagRegionIDKey];
        if (region_id) {
            [region setObject:region_id forKey:inbeaconsTagRegionIDKey];
            [self monitoringRegion:region];
        }
    }];
}

- (void)monitoringRegion:(NSDictionary *)region
{
    INBLog(@"point of interest: %@", region);
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        
        NSString *s_uuid = [region objectForKey:inbeaconsTagUuidKey];
        if (s_uuid != nil && [s_uuid length] > 0) {
            NSArray *uuids = [s_uuid componentsSeparatedByString:@","];
            [uuids enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                INBLog(@"request for monitoring poi with UUID: %@", obj);
                
                NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:obj];
                NSString *region_id = [region objectForKey:inbeaconsTagRegionIDKey];
                if ([_regions objectForKey:region_id] == nil) {
                    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:region_id];
                    beaconRegion.notifyEntryStateOnDisplay = YES;
                    if (beaconRegion != nil) {
                        [self.locationManager startMonitoringForRegion:beaconRegion];
                        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
                        
                        NSDictionary *dict = @{
                                               inbeaconsTagEnterMessageRegionKey: [region objectForKey:inbeaconsTagEnterMessageRegionKey],
                                               inbeaconsTagExitMessageRegionKey: [region objectForKey:inbeaconsTagExitMessageRegionKey],
                                               inbeaconsTagRegionKey: beaconRegion,
                                               inbeaconsTagUuidKey: s_uuid,
                                               inbeaconsTagRegionIDKey : region_id
                                               };
                        [_regions setValue:dict forKey:region_id];
                    }
                }
            }];
        }
    }
    else {
        NSString *msg = @"Your device does not support monitoring region beacons";
        INBLog(@"%@", msg);
        
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:kCLErrorDenied userInfo:@{ NSLocalizedDescriptionKey: msg}];
        [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidFailWithErrorNotification object:error];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didFailWithError:)])
            [self.delegate inbeacons:self didFailWithError:error];
    }
}

- (void)enterRegion:(NSDictionary*)region
{
    _isEnteredRegion = YES;
    NSString *region_id = [self.region objectForKey:inbeaconsTagRegionIDKey];
    NSString *msg = [self.region objectForKey:inbeaconsTagEnterMessageRegionKey];
    [self sendLocalNotification:msg toRegionID:region_id forAction:inbeaconsRegionActionEnterRegion];

    if (self.beacons == nil)
        self.beacons = [NSMutableDictionary new];
    
    CLBeaconRegion *beacon = [self.region objectForKey:inbeaconsTagRegionKey];
    [self.locationManager startRangingBeaconsInRegion:beacon];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidEnterRegionNotification object:self.region];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didEnterRegion:)])
        [self.delegate inbeacons:self didEnterRegion:self.region];
    
}

- (void)exitRegion:(NSDictionary*)region
{
    _isEnteredRegion = NO;
    NSString *region_id = [self.region objectForKey:inbeaconsTagRegionIDKey];
    NSString *msg = [self.region objectForKey:inbeaconsTagExitMessageRegionKey];
    [self sendLocalNotification:msg toRegionID:region_id forAction:inbeaconsRegionActionExitRegion];
    
    CLBeaconRegion *beacon = [self.region objectForKey:inbeaconsTagRegionKey];
    [self.locationManager stopRangingBeaconsInRegion:beacon];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidExitRegionNotification object:self.region];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didExitRegion:)])
        [self.delegate inbeacons:self didExitRegion:self.region];
}

#pragma mark - Local Notifications

-(void)sendLocalNotification:(NSString *)message toRegionID:(NSString *)regionID forAction:(inbeaconsRegionActions)regionAction
{
    if (([UIApplication sharedApplication].applicationState != UIApplicationStateActive) && ([message length] > 0)) {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        
        UILocalNotification *notice = [[UILocalNotification alloc] init];
        notice.alertBody = message;
        notice.alertAction = @"Open";
        notice.soundName = UILocalNotificationDefaultSoundName;
        notice.userInfo = @{ inbeaconsTagActionKey:[NSString stringWithFormat:@"%i", (int)regionAction], inbeaconsTagRegionIDKey: regionID };
        
        INBLog(@"userInfo: %@", notice.userInfo);
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
    }
}

#pragma mark - inbeacons APIs

- (void)getPlacesWithToken:(NSString*)token
{
    _token = token;
    
    [self invokeAPI:inbeaconsGetPlaces];
}

- (void)getRuleWithToken:(NSString*)token uuid:(NSString*)uuid major:(long)major minor:(long)minor
{
    _token = token;
    self.uuid = uuid;
    self.major = major;
    self.minor = minor;
    
    [self invokeAPI:inbeaconsGetRule];
}

- (void)setPlaceAction:(inbeaconsRegionActions)action token:(NSString*)token region:(NSDictionary*)region
{
    _token = token;
    self.regionActions = action;
    self.region = region;
    
    [self invokeAPI:inbeaconsSetPlaceAction ];
}

- (void)invokeAPI:(inbeaconsAPI)apiInvoke
{
    self.apiInvoked = apiInvoke;
    
    NSString *urlString = nil;
    switch (apiInvoke) {
        case inbeaconsLogin:
            urlString = [NSString stringWithFormat:@"%@/%@/%@/%@", inbeaconsBaseDomain, inbeaconsAPILoginKey, self.username, self.password];
            break;
            
        case inbeaconsGetPlaces:
            urlString = [NSString stringWithFormat:@"%@/%@/%@", inbeaconsBaseDomain, inbeaconsAPIGetPlacesKey, self.token];
            break;
            
        case inbeaconsGetRule:
            urlString = [NSString stringWithFormat:@"%@/%@/%@/%@/%ld/%ld", inbeaconsBaseDomain, inbeaconsAPIGetRuleKey, self.token, self.uuid, self.major, self.minor];
            break;
            
        case inbeaconsSetPlaceAction:
            switch (_regionActions) {
                case inbeaconsRegionActionEnterRegion:
                    urlString = [NSString stringWithFormat:@"%@/%@/%@/%@/%@", inbeaconsBaseDomain, inbeaconsAPISetPlacesActionKey, self.token, [self.region objectForKey:inbeaconsTagRegionIDKey], inbeaconsAPIEnterRegionKey];
                    break;
                    
                case inbeaconsRegionActionExitRegion:
                    urlString = [NSString stringWithFormat:@"%@/%@/%@/%@/%@/%@", inbeaconsBaseDomain, inbeaconsAPISetPlacesActionKey, self.token, [self.region objectForKey:inbeaconsTagRegionIDKey], inbeaconsAPIExitRegionKey, self.regionParentID];
                    break;
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    INBLog(@"request: %@", url);
    
    _webData = [NSMutableData new];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:_timeout];
    [request setValue:NSStringFromClass([self class]) forHTTPHeaderField:@"User-Agent"];
    
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (_connection == nil) {
        
        NSString *msg = @"inbeacons invalid connection!";
        INBLog(@"%@", msg);
        
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : msg};
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:kCLErrorNetwork userInfo:userInfo];
        [self connection:nil didFailWithError:error];
    }
}

#pragma mark - NSURLConnection Delegates

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (_webData)
        [_webData setLength:0];
    
    if ([response respondsToSelector:@selector(statusCode)])
    {
        _statusCode = [((NSHTTPURLResponse *)response) statusCode];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (_webData)
        [_webData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    INBLog(@"inbeacons connection fail! - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    _connection = nil;
    _webData = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidFailWithErrorNotification object:error];

    if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didFailWithError:)])
        [self.delegate inbeacons:self didFailWithError:error];
    
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _connection = nil;
    
    NSDictionary *responseDict = nil;
    
    if (_webData != nil) {
        NSError *error = nil;
        responseDict = [NSJSONSerialization JSONObjectWithData:_webData options:0 error:&error];
        if (error != nil) {
            [self connection:nil didFailWithError:error];
            return;
        }
    }
    
    INBLog(@"inbeacons response: %@", responseDict);
    
    switch (self.apiInvoked) {
        case inbeaconsLogin:
            self.apiInvoked = inbeaconsNone;
            if ([[responseDict objectForKey:inbeaconsTagResponseKey] isEqualToString:inbeaconsResponseOK]) {
                _token = [responseDict objectForKey:inbeaconsTagTokenKey];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidUserLoggedinNotification object:responseDict];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didUserLoggedin:)])
                    [self.delegate inbeacons:self didUserLoggedin:responseDict];
                
            } else {
                NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:kCLErrorDenied userInfo:responseDict];
                [[NSNotificationCenter defaultCenter] postNotificationName:inbeaconsDidFailWithErrorNotification object:error];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(inbeacons:didFailWithError:)])
                    [self.delegate inbeacons:self didFailWithError:error];
            }
            break;
            
        case inbeaconsGetPlaces:
            self.apiInvoked = inbeaconsNone;
            [self startMonitoringForRegions:responseDict];
            break;
            
        case inbeaconsGetRule:
            self.apiInvoked = inbeaconsNone;
            if (self.nearestBeacon != nil && self.beacons != nil && responseDict != nil) {
                NSString *key = [NSString stringWithFormat:@"%@_%@", self.nearestBeacon.major, self.nearestBeacon.minor];
                [self.beacons setObject:responseDict forKey:key];
                [self checkProximityWithNearestBeacon:self.nearestBeacon key:key];
            }
            break;
            
        case inbeaconsSetPlaceAction:
            self.apiInvoked = inbeaconsNone;
            if (self.region != nil) {
                switch (self.regionActions) {
                    case inbeaconsRegionActionEnterRegion:
                        self.regionParentID = [responseDict objectForKey:inbeaconsTagRegionParentIDKey];
                        [self enterRegion:self.region];
                        break;
                        
                    case inbeaconsRegionActionExitRegion:
                        [self exitRegion:self.region];
                        break;
                        
                    default:
                        break;
                }
            }
            break;
            
        default:
            break;
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

@end
