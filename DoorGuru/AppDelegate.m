//
//  AppDelegate.m
//  DoorGuru
//
//  Created by Grzegorz Lesiak on 05/12/14.
//  Copyright (c) 2014 netguru. All rights reserved.
//

#import "AppDelegate.h"
#import <GooglePlus/GooglePlus.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (BOOL)application: (UIApplication *)application openURL: (NSURL *)url sourceApplication: (NSString *)sourceApplication
         annotation: (id)annotation
{
    return [GPPURLHandler handleURL:url
                  sourceApplication:sourceApplication
                         annotation:annotation];
}
@end
