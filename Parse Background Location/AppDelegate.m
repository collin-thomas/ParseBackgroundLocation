//
//  AppDelegate.m
//  Parse Background Location
//
//  Created by Collin Thomas on 9/14/15.
//  Copyright (c) 2015 WDZ LLC. All rights reserved.
//

#import "AppDelegate.h"

#import <Parse/Parse.h>

#import "WDZLocationManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // [Optional] Power your app with Local Datastore. For more info, go to
    // https://parse.com/docs/ios_guide#localdatastore/iOS
    [Parse enableLocalDatastore];
    
    // Initialize Parse.
    [Parse setApplicationId:@"myj2jUXnKKep3ftHfVdEHSixLhzKaooOczbSEvIl"
                  clientKey:@"uCoLas6xrZGmza1ZvuhxdcaFeLYmeN9MhuapUd9X"];
    
    // [Optional] Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    
    
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey]) {
        NSLog(@"app started because a region update occured");
        
        NSLog(@"%lu", (unsigned long)[[WDZLocationManager sharedInstance] locationManager].monitoredRegions.count);
        
        // 1.
        // if there is already a region being monitored no need to kick off the process
        // also make sure location service is working
        if ([[WDZLocationManager sharedInstance] locationManager].monitoredRegions.count == 0) {
            if ([[WDZLocationManager sharedInstance] checkLocationManager]) {
                [[WDZLocationManager sharedInstance] startUpdatingLocation];
            }
        } else {
            // Ask for state of currently monitored region
            CLCircularRegion *region = [[[[WDZLocationManager sharedInstance] locationManager].monitoredRegions allObjects] lastObject];
     
            if (region) {
                NSLog(@"UIApplicationLaunchOptionsLocationKey");
                // set the region, should cue update to interface
                
                [WDZLocationManager sharedInstance].regionIdentifier = region.identifier;
                [WDZLocationManager sharedInstance].region = region;
                
                
                [[[WDZLocationManager sharedInstance] locationManager] requestStateForRegion:region];
            }
        }
    }

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // if no regions are being monitored and the user doesn't kill and launch
    // but just opens app from background then call what we do above to start the show
    if ([[WDZLocationManager sharedInstance] locationManager].monitoredRegions.count == 0) {
        if ([[WDZLocationManager sharedInstance] checkLocationManager]) {
            [[WDZLocationManager sharedInstance] startUpdatingLocation];
        }
    } else {
        // Ask for state of currently monitored region
        CLCircularRegion *region = [[[[WDZLocationManager sharedInstance] locationManager].monitoredRegions allObjects] lastObject];
        
        if (region) {
            NSLog(@"did become active");
            
            // set the region, should cue update to interface
            // importatn for this to go fisrt because we are monitorign the region to change and it is that fast!
            [WDZLocationManager sharedInstance].regionIdentifier = region.identifier;
            [WDZLocationManager sharedInstance].region = region;
            
            [[[WDZLocationManager sharedInstance] locationManager] requestStateForRegion:region];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
