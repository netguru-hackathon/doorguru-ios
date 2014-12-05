//
//  ViewController.h
//  DoorGuru
//
//  Created by Grzegorz Lesiak on 05/12/14.
//  Copyright (c) 2014 netguru. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GooglePlus/GooglePlus.h>
#import <CoreLocation/CoreLocation.h>
#import <EstimoteSDK/ESTBeaconManager.h>

@class GPPSignInButton;

@interface ViewController : UIViewController <GPPSignInDelegate,CLLocationManagerDelegate,ESTBeaconManagerDelegate>

@property (retain, nonatomic) IBOutlet GPPSignInButton *signInButton;

@end

