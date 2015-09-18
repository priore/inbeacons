# inBeaconsSDK
inBeacons iOS SDK for Estimote beacons devices and http://www.inbacons.com Cloud CMS.

```objective-c
	#import "inbeacons.h"
	
	@interface ViewController () <inbeaconsDelegate>
	
	@property (nonatomic, strong) inbeacons *inbeaconsSDK; // important!
	
	@end
	
	@implementation ViewController
	
	- (void)viewDidLoad {
    	[super viewDidLoad];
	    
    	self.inbeaconsSDK = [inbeacons new];
    	self.inbeaconsSDK.delegate = self; // or you can use the notifications
    	// inbeacons.com logins
    	[self.inbeaconsSDK loginWithUsername:@"your-useremail" password:@"your-password"];
	}
	
	#pragma mark - inBeacons Delegates
	
	- (void)inbeacons:(inbeacons *)inbeacon didEnterRegion:(NSDictionary *)region
	{
    	NSLog(@"Enter region: %@", region);
	}
	
	- (void)inbeacons:(inbeacons *)inbeacon didExitRegion:(NSDictionary *)region
	{
    	NSLog(@"Exit region: %@", region);
	}
	
	- (void)inbeacons:(inbeacons *)inbeacon didFailWithError:(NSError *)error
	{
    	NSLog(@"ERROR: %@", error);
	}
	
	- (void)inbeacons:(inbeacons *)inbeacon didNearestBeacon:(NSDictionary *)beacon proximity:(int)proximity
	{
    	NSLog(@"Nearest beacon: %@", beacon);
	    
    	switch (proximity) {
        	case 0: // unknow
            	break;
        	case 1: // immediate
            	break;
        	case 2: // near
            	break;
        	case 3: // far
            	break;
        	default:
            	break;
    	}
	}
	
	- (void)inbeacons:(inbeacons *)inbeacon didUserLoggedin:(NSDictionary *)userInfo
	{
    	NSLog(@"User logged: %@", userInfo);
    	// automatic start monitoring after user loggedin
    	[inbeacon startMonitoring];
	}
	
	@end
```
