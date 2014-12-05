//
//  ViewController.m
//  DoorGuru
//
//  Created by Grzegorz Lesiak on 05/12/14.
//  Copyright (c) 2014 netguru. All rights reserved.
//

#import "ViewController.h"
#import <GoogleOpenSource/GoogleOpenSource.h>
#import <AFNetworking/AFNetworking.h>

#define kClientId @"1006152281796-phenl6vgsqijcq0cj8lde5nm6h150t6d.apps.googleusercontent.com"
#define kClientSecret @"ygM_5vhCG6OI73KLFqCuxOQ6"
#define kBeaconId @"B9407F30-F5F8-466E-AFF9-25556B57FE6D"
#define baseURLString @"https://doorguru.herokuapp.com:443/"
#define kBeaconRegionId @"co.netguru.doorGuru"
#define doorResponseKey @"door"
#define doorStatusKey @"open"

@interface ViewController ()


@property (nonatomic,strong) ESTBeaconRegion * beaconRegion;
@property (nonatomic,strong) ESTBeaconManager * beaconManager;
@property (nonatomic,strong) CLLocationManager * locationManager;
@property (nonatomic,strong) GTMOAuth2Authentication * auth;
@property (nonatomic,strong) NSString * token;
@property (nonatomic,assign) BOOL inRange;
@property (nonatomic,assign) BOOL doorOpened;


@end

@implementation ViewController

@synthesize signInButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[self setupGoogle];
    //[self setupLocationManager];
    [self setupEstimote];
}

- (void) setupEstimote
{
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString: kBeaconId];
    
    
    self.beaconRegion = [[ESTBeaconRegion alloc] initWithProximityUUID:uuid
                                                            identifier:@"DoorGuru"];
    self.beaconRegion.notifyOnEntry = YES;
    self.beaconRegion.notifyOnExit = YES;
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
    
    [self.beaconManager startRangingBeaconsInRegion: self.beaconRegion];
}

- (void) setupGoogle
{
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.shouldFetchGooglePlusUser = YES;
    signIn.shouldFetchGoogleUserEmail = YES;  // Uncomment to get the user's email
    
    // You previously set kClientId in the "Initialize the Google+ client" step
    signIn.clientID = kClientId;
    
    // Uncomment one of these two statements for the scope you chose in the previous step
    //signIn.scopes = @[ kGTLAuthScopePlusLogin ];  // "https://www.googleapis.com/auth/plus.login" scope
    signIn.scopes = @[ @"profile" ];            // "profile" scope
    
    // Optional: declare signIn.actions, see "app activities"
    signIn.delegate = self;
    
    [signIn trySilentAuthentication];
}

-(void)refreshInterfaceBasedOnSignIn {
    if ([[GPPSignIn sharedInstance] authentication]) {
        // The user is signed in.
        self.signInButton.hidden = YES;
        // Perform other actions here, such as showing a sign-out button
    } else {
        self.signInButton.hidden = NO;
        // Perform other actions here
    }
}

#pragma mark Estimote Delegate

- (void)beaconManager:(ESTBeaconManager *)manager didEnterRegion:(ESTBeaconRegion *)region
{
    NSLog(@"Enter region notification");
}

- (void)beaconManager:(ESTBeaconManager *)manager didExitRegion:(ESTBeaconRegion *)region
{
    NSLog(@"Exit region notification");
}

-(void)beaconManager:(ESTBeaconManager *)manager
     didRangeBeacons:(NSArray *)beacons
            inRegion:(ESTBeaconRegion *)region
{
    ESTBeacon * closestBeacon;
    if( [beacons count] > 0)
    {
        closestBeacon = [beacons firstObject];
        NSString * beaconUUID = [closestBeacon.proximityUUID UUIDString];
        NSLog( @"found beacon: %@ (%@)", beaconUUID, [self nameForProximity: closestBeacon.proximity] );
        if ( closestBeacon.proximity==CLProximityImmediate)
        {
            self.inRange = YES;
            [self sendRequest];
        }
        else
        {
            self.inRange = NO;
        }
    }
}

- (NSString*) nameForProximity: (CLProximity) proximity
{
    switch (proximity)
    {
        case CLProximityImmediate:
            return @"immediate";
        case CLProximityNear:
            return @"near";
        case CLProximityFar:
            return @"far";
        default:
            return @"unknown";
    }
}

#pragma mark GPPSignInDelegate

- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth
                   error: (NSError *) error {
    NSLog(@"Received error %@ and auth object %@",error, auth);

    if (error) {
        // Do some error handling here.
        self.auth = nil;
        NSLog( @"google authentication failed" );
    } else {
        [self refreshInterfaceBasedOnSignIn];
        self.auth = auth;
        NSLog( @"user authenticated" );
        [self sendRequest];
    }
}

- (void) setDoorOpened:(BOOL)doorOpened
{
    if (doorOpened==YES)
    {
        NSTimer * doorTimer = [NSTimer scheduledTimerWithTimeInterval: 5 target:self selector: @selector(closeDoor) userInfo:nil repeats:NO];
        [doorTimer fire];
        [[NSRunLoop mainRunLoop] addTimer:doorTimer forMode:NSDefaultRunLoopMode];
    }
    _doorOpened = doorOpened;
}

- (void) closeDoor
{
    self.doorOpened = NO;
    NSLog( @"door closed" );
}

#pragma mark Network Methods

- (void) sendRequest
{
    if ( self.inRange && !self.doorOpened )
    {
        NSURL * baseURL = [NSURL URLWithString: baseURLString];
        AFHTTPRequestOperationManager * httpOperationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL: baseURL];
        [httpOperationManager POST: @"/v1/open.json" parameters: @{@"key":@"cea3fa89bfc0aae84fde322fdaffc500"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog( @"success with response object %@", responseObject );
            
            if ( [responseObject isKindOfClass:[NSDictionary class]])
            {
                NSDictionary * responseDictionary = (NSDictionary*) responseObject;
                NSDictionary * doorDictionary = responseObject[doorResponseKey];
                if ( [doorDictionary[doorStatusKey] boolValue] )
                {
                    NSLog( @"door opened" );
                    self.doorOpened = YES;
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog( @"failed with error %@", error);
        }];
    }
}


@end
