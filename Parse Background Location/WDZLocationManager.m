//
//  WDZLocationManager.m
//  Background Location
//
//  Created by Collin Thomas on 9/9/15.
//  Copyright (c) 2015 WDZ LLC. All rights reserved.
//

#import "WDZLocationManager.h"

#import <Parse/Parse.h>

@import UIKit;

@implementation WDZLocationManager

@synthesize locationManager;

+(WDZLocationManager *) sharedInstance
{
    static WDZLocationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WDZLocationManager alloc]init];
    });
    return instance;
}

-(id) init
{
    self = [super init];
    //if(self != nil) {
    if(self)
    {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        // 100 is probably the lowest you can go, 65 seems to be iphone 5 limit.
        self.locationManager.desiredAccuracy = 130.00;
        
        // radius should be larger than the desiredAccuracy
        self.regionRadius = [NSNumber numberWithDouble:300.00];
        
        // if the radius is too big then set it to the max
        if (self.regionRadius > [NSNumber numberWithDouble:self.locationManager.maximumRegionMonitoringDistance]) {
            self.regionRadius = [NSNumber numberWithDouble:self.locationManager.maximumRegionMonitoringDistance];
        }
        
        // if you don't have one of these then likes to fire off a couple extra
        // location updates even though you've got one you like already and said stop.
        // we set it to 50 because even though 65 is the hardware limit it will give us best
        // possible without it firing extra updates.
        self.locationManager.distanceFilter = 65.00;
        
        [self.locationManager requestAlwaysAuthorization];
    }
    return self;
}

- (void)newRegionIdentifier {
    NSDateFormatter *formatter;
    NSString        *dateString;
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm:ss.SSS"];
    dateString = [formatter stringFromDate:[NSDate date]];
    NSString *name = [NSString stringWithFormat:@"wdz-"];
    self.regionIdentifier = [name stringByAppendingString:dateString];
}

- (BOOL)checkLocationManager
{
    if(![CLLocationManager locationServicesEnabled])
    {
        [self showMessage:@"You need to enable Location Services"];
        return NO;
    }
    if(![CLLocationManager isMonitoringAvailableForClass:[CLRegion class]])
    {
        [self showMessage:@"Region monitoring is not available for this Class"];
        return NO;
    }
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
       [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted  )
    {
        [self showMessage:@"You need to authorize Location Services for the APP"];
        return NO;
    }
    return YES;
}

// 6.
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Exited Region - %@", region.identifier);
    
    // 7.
    [self removeRegion:region];
    
    // 8.
    [self startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {

    NSLog(@"Region Failure - %@", [error localizedDescription]);
    
    [self saveError:error];
    
    [self showMessage:@"Failure to monitor region"];
    
    // you could retry here
    //[self removeAllRegions];
    //[self startUpdatingLocation];
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Location Failure - %@", [error localizedDescription]);
    
    [self saveError:error];
    
    [self showMessage:@"We could not determine your location"];
}


// delegate method that gets called if a new region is being monitored.
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"Now Monitoring Region - %@", region.identifier);
    
    // Ask for state of currently monitored region
    // caused error. idk stackoverflow someone said they saw it too
    // 
    // kCLErrorDomain error 5.
    /*
    if (region) {
        [[[WDZLocationManager sharedInstance] locationManager] requestStateForRegion:region];
    }
    */
    
    // save to parse
    [self testParse];
}

- (void)startUpdatingLocation
{
    NSLog(@"Starting location updates");
    if ([self checkLocationManager]) {
        [self.locationManager startUpdatingLocation];
    }
}

// delegate method that responds to requestStateForRegion
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (state == CLRegionStateInside)
    {
        self.regionState = @"inside";
    }
    else if (state == CLRegionStateOutside)
    {
        self.regionState = @"outside";
    }
    else if (state == CLRegionStateUnknown)
    {
        self.regionState = @"unknown";
    }
}

- (void)stopUpdatingLocation
{
    NSLog(@"Stopping location updates");
    [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray*)locations
{
    NSLog(@"locations count %lu", (unsigned long)[locations count]);
    
    CLLocation *location = [locations lastObject];
    
    NSLog(@"Latitude %+.6f, Longitude %+.6f\n",
          location.coordinate.latitude,
          location.coordinate.longitude);
    
    if ([locations count] > 1) {
    
        CLLocation *secondToLastLocation = [locations objectAtIndex:[locations count] - 1];
    
        CLLocationDistance distance = [secondToLastLocation distanceFromLocation:location];
    
        NSLog(@"Distance - %f", distance);
        
        NSLog(@"LLLatitude %+.6f, LLLLongitude %+.6f\n",
              secondToLastLocation.coordinate.latitude,
              secondToLastLocation.coordinate.longitude);

        // region radius
        if (distance <= 200) {
            return;
        }
    }
    
    // apple code
    // test age to make sure it is not cached
    // locationAge is measured in seconds
    NSTimeInterval locationAge = -[location.timestamp timeIntervalSinceNow];
    NSLog(@"locationAge - %f", locationAge);
    if (locationAge > 10.0) {
        return;
    }
    
    // apple code
    // test horizontal accuracy for invalid measurement
    if (location.horizontalAccuracy < 0) {
        NSLog(@"horizontalAccuracy less than 0 - %f", location.horizontalAccuracy);
        return;
    }
    
    NSLog(@"horizontalAccuracy - %f", location.horizontalAccuracy);
    
    // true if the new location's accuracy is closer in meters than what we've defined
    if (location.horizontalAccuracy <= self.locationManager.desiredAccuracy) {
        
        self.currentLocation = location;
            
        // 2.
        [self stopUpdatingLocation];
            
        // 3.
        [self addRegion];
        
    }
}

- (CLRegion*)dictToRegion:(NSDictionary*)dictionary
{
    NSString *identifier = [dictionary valueForKey:@"identifier"];
    CLLocationDegrees latitude = [[dictionary valueForKey:@"latitude"] doubleValue];
    CLLocationDegrees longitude =[[dictionary valueForKey:@"longitude"] doubleValue];
    CLLocationDistance regionRadius = [[dictionary valueForKey:@"radius"] doubleValue];
    
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    if(regionRadius > self.locationManager.maximumRegionMonitoringDistance)
    {
        regionRadius = self.locationManager.maximumRegionMonitoringDistance;
    }
    
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:centerCoordinate
                                                                radius:regionRadius
                                                            identifier:identifier];
    
    return region;
}

-(void) showMessage:(NSString *) message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Geofence"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:Nil, nil];
    
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    
    [alertView show];
}

- (void)addRegion
{
    // 4.
    
    // make sure there isn't a region already being monitored by us
    // safe gaurd from multiple location updates creating multiple regions
    // things like mapkit regions/user tracking can fire off a lot of location updates
    if ([self.locationManager.monitoredRegions allObjects].count != 0) {
        NSLog(@"Region is already being montiored - %@ ", self.regionIdentifier);
        return;
    }
    
    CLLocationCoordinate2D coordiate = self.currentLocation.coordinate;
    
    [self newRegionIdentifier];
    
    NSDictionary *regionDictionary = @{
        @"identifier" : self.regionIdentifier,
        @"latitude" : [NSNumber numberWithDouble:(double)coordiate.latitude],
        @"longitude" : [NSNumber numberWithDouble:(double)coordiate.longitude],
        @"radius" : self.regionRadius};
    
    CLRegion * region = [self dictToRegion:regionDictionary];
    
    region.notifyOnEntry = NO;
    region.notifyOnExit = YES;
    
    
    // 5.
    [self.locationManager startMonitoringForRegion:region];
    
    NSLog(@"Started Monitoing Region - %@", region.identifier);
}

- (void)removeRegion:(CLRegion *)region
{
    // stop monitoring
    [self.locationManager stopMonitoringForRegion:region];
    
    NSLog(@"Stopped Monitoing Region - %@", region.identifier);
}

- (void)removeAllRegions
{
    NSArray * monitoredRegions = [self.locationManager.monitoredRegions allObjects];
    
    for(CLRegion *region in monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
        NSLog(@"Stopped Monitoing Region - %@", region.identifier);
    }
}

- (void)testNetworking
{
    // NSURL
    NSURL *url = [NSURL URLWithString:@"http://jsonplaceholder.typicode.com/posts/1"];
    
    // URLRequest
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];

    // Queue
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response,NSData *data, NSError *error) {
        
        if ([data length] >0 && error == nil) {
            NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@", newStr);
        } else if ([data length] == 0 && error == nil) {
            NSLog(@"Nothing was downloaded.");
        } else if (error != nil) {
            NSLog(@"Error = %@", error);
        }
    }];
}

- (void)testParse
{
    NSString *lat = [NSString stringWithFormat:@"%+.6f", self.locationManager.location.coordinate.latitude];
    NSString *lng = [NSString stringWithFormat:@"%+.6f", self.locationManager.location.coordinate.longitude];
    
    PFObject *region = [PFObject objectWithClassName:@"Regions"];
    region[@"lat"] = lat;
    region[@"lng"] = lng;
    region[@"region"] = self.regionIdentifier;
    region[@"info"] = @"hansIphone";
    
    [region saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"succcess saving to parse");
        } else {
            NSLog(@"parse error - %@", error.description);
        }
    }];
}

- (void) saveError:(NSError *)error
{
    if ([error localizedDescription] != nil) {
        PFObject *err = [PFObject objectWithClassName:@"Errors"];
        err[@"desc"] = [error localizedDescription];
        [err saveInBackground];
    }
}

@end
