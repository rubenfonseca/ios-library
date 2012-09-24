/*
 Copyright 2009-2012 Urban Airship Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <SenTestingKit/SenTestingKit.h>
#import <OCMock/OCMock.h>
#import <OCMock/OCMConstraint.h>

#import "UALocationService.h"
#import "UALocationService+Internal.h"
#import "UALocationEvent.h"
#import "UALocationCommonValues.h"
#import "UAirship.h"
#import "UAAnalytics.h"
#import "UALocationTestUtils.h"
#import "UAStandardLocationProvider.h"
#import "UASignificantChangeProvider.h"



@interface UALocationEventApplicationTests : SenTestCase {
    CLLocation *location;
}
@end
// TODO: Check on whether the session_id is actually going up if you take it out of the 
// payload

/**
 *  The context includes all the data necessary for a 
 *  location event. These are:
 *  
 *  "session_id": "UUID"
 *  "lat" : "31.3847" (required, DDD.dddd... string double)
 *  "long": "32.3847" (required, DDD.dddd... string double)
 *  "requested_accuracy": "10.0,100.0,NONE" (required, requested accuracy in meters as a string double)
 *  "update_type": "CHANGE, CONTINUOUS, SINGLE, NONE" (required - string enum)
 *  "provider": "GPS, NETWORK, PASSIVE, UNKNOWN" (required - string enum)
 *  "update_dist": "10.0,100.0,NONE" (required - string double distance in meters, or NONE if not available applicable)
 *  "h_accuracy": "10.0, NONE" (required, string double - actual horizontal accuracy in meters, or NONE if not available)
 *  "v_accuracy": "10.0, NONE" (required, string double - actual vertical accuracy in meters, or NONE if not available)
 *  "foreground": "true" (required, string boolean)
 */

@implementation UALocationEventApplicationTests

- (void)setUp {
    location = [[UALocationTestUtils testLocationPDX] retain];
}

- (void)tearDown {
    RELEASE(location);
}

- (void)testInitWithLocationManager {
    CLLocationManager *locationManager = [[[CLLocationManager alloc] init] autorelease];
    UALocationEvent *event = [UALocationEvent locationEventWithLocation:location 
                                                        locationManager:locationManager 
                                                          andUpdateType:UALocationEventUpdateTypeSingle];
    NSDictionary *data = event.data;
    
    // 0.000001 equals sub meter accuracy at the equator. 
    STAssertEqualsWithAccuracy(location.coordinate.latitude, [[data valueForKey:UALocationEventLatitudeKey] doubleValue], 0.000001, nil);
    STAssertEqualsWithAccuracy(location.coordinate.longitude, [[data valueForKey:UALocationEventLongitudeKey] doubleValue],0.000001 ,nil);
    STAssertEquals((int)location.horizontalAccuracy, [[data valueForKey:UALocationEventHorizontalAccuracyKey] intValue],nil);
    STAssertEquals((int)location.verticalAccuracy, [[data valueForKey:UALocationEventVerticalAccuracyKey] intValue],nil);
    STAssertEquals((int)locationManager.desiredAccuracy, [[data valueForKey:UALocationEventDesiredAccuracyKey] intValue],nil);
    // update_type
    STAssertEquals((int )locationManager.distanceFilter, [[data valueForKey:UALocationEventDistanceFilterKey] intValue] ,nil);
    STAssertTrue((UALocationEventUpdateTypeSingle == [data valueForKey:UALocationEventUpdateTypeKey]) ,nil);
    STAssertTrue((UAAnalyticsTrueValue == [data valueForKey:UALocationEventForegroundKey]), nil);
    STAssertTrue((UALocationServiceProviderUnknown == [data valueForKey:UALocationEventProviderKey]), nil);

}


- (void)testInitWithProvider {
    UAStandardLocationProvider *standard = [UAStandardLocationProvider providerWithDelegate:nil];
    UALocationEvent *event = [UALocationEvent locationEventWithLocation:location provider:standard andUpdateType:UALocationEventUpdateTypeContinuous];
    NSDictionary *data = event.data;
    STAssertEqualsWithAccuracy(location.coordinate.latitude, [[data valueForKey:UALocationEventLatitudeKey] doubleValue], 0.000001, nil);
    STAssertEqualsWithAccuracy(location.coordinate.longitude, [[data valueForKey:UALocationEventLongitudeKey] doubleValue],0.000001, nil);
    STAssertEquals(location.horizontalAccuracy, [[data valueForKey:UALocationEventHorizontalAccuracyKey] doubleValue], nil);
    STAssertEquals(location.verticalAccuracy, [[data valueForKey:UALocationEventVerticalAccuracyKey] doubleValue], nil);
    //TODO: add tests after the UALocationService pass through is completed
    STAssertEquals(standard.desiredAccuracy, [[data valueForKey:UALocationEventDesiredAccuracyKey] doubleValue],nil);
    STAssertEquals(standard.distanceFilter, [[data valueForKey:UALocationEventDistanceFilterKey] doubleValue] ,nil);
    STAssertTrue((UALocationEventUpdateTypeContinuous == [data valueForKey:UALocationEventUpdateTypeKey]) ,nil);
    STAssertTrue((UAAnalyticsTrueValue == [data valueForKey:UALocationEventForegroundKey]), nil);
    STAssertTrue((UALocationServiceProviderGps == [data valueForKey:UALocationEventProviderKey]), nil);
    
}

- (void)testInitWithSigChangeProviderSetsDistanceFilterDesiredAccuracyNone {
    UASignificantChangeProvider *sigChange = [UASignificantChangeProvider providerWithDelegate:nil];
    UALocationEvent *event = [UALocationEvent locationEventWithLocation:location provider:sigChange andUpdateType:UALocationEventUpdateTypeChange];
    STAssertTrue(UAAnalyticsValueNone == [event.data valueForKey:UALocationEventDesiredAccuracyKey], @"desiredAccuracy should be UADesiredAccuracyValueNone");
    STAssertTrue(UAAnalyticsValueNone == [event.data valueForKey:UALocationEventDistanceFilterKey], @"distanceFilter should be UADistanceFilterValueNone");
}


@end
