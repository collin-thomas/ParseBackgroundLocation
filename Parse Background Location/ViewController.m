//
//  ViewController.m
//  Parse Background Location
//
//  Created by Collin Thomas on 9/14/15.
//  Copyright (c) 2015 WDZ LLC. All rights reserved.
//

#import "ViewController.h"

#import "WDZLocationManager.h"

@import MapKit;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *regionIdentifier;
@property (weak, nonatomic) IBOutlet UILabel *regionState;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)removeBtn:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Monitor for when there is a new region
    [[WDZLocationManager sharedInstance] addObserver:self forKeyPath:@"region" options:NSKeyValueObservingOptionNew context:nil];
    
    [[WDZLocationManager sharedInstance] addObserver:self forKeyPath:@"regionState" options:NSKeyValueObservingOptionNew context:nil];
}

// delegate that fires from observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object  change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"region"]) {
        
        //CLLocation *location = [WDZLocationManager sharedInstance].currentLocation;
        CLLocationDegrees latitude = [WDZLocationManager sharedInstance].region.center.latitude;
        CLLocationDegrees longitude = [WDZLocationManager sharedInstance].region.center.longitude;
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        
        self.label.text = [NSString stringWithFormat:@"Latitude %+.6f\nLongitude %+.6f", latitude, longitude];
        
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        [annotation setCoordinate:location.coordinate];
        [annotation setTitle:[WDZLocationManager sharedInstance].regionIdentifier];
        [self.mapView addAnnotation:annotation];
       
        
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500);
        MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
        [self.mapView setRegion:adjustedRegion animated:YES];
        //[self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
        
        NSString *id = [WDZLocationManager sharedInstance].regionIdentifier;
        if (id != nil) {
            self.regionIdentifier.text = id;
        }
    }
    
    if([keyPath isEqualToString:@"regionState"]) {
        
        NSString *state = [WDZLocationManager sharedInstance].regionState;
        if (state != nil) {
            self.regionState.text = state;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)removeBtn:(id)sender {
    [[WDZLocationManager sharedInstance] removeAllRegions];
    
    NSMutableArray * annotationsToRemove = [ self.mapView.annotations mutableCopy ] ;
    [ annotationsToRemove removeObject:self.mapView.userLocation ] ;
    [ self.mapView removeAnnotations:annotationsToRemove ] ;
}
@end
