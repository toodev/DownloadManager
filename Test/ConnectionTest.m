//
//  ConnectionTest.m
//  DownloadManager
//
//  Created by Daniele Poggi on 5/24/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "ConnectionTest.h"
#import "TDDownload.h"

@implementation ConnectionTest

#if USE_APPLICATION_UNIT_TEST     // all code under test is in the iPhone Application

- (void) testAppDelegate {
    
    id yourApplicationDelegate = [[UIApplication sharedApplication] delegate];
    STAssertNotNil(yourApplicationDelegate, @"UIApplication failed to find the AppDelegate");    
}

#else                           // all code under test must be linked into the Unit Test bundle

- (void) testMath {
    
    TDDownload *connection = [[TDDownload alloc] init];
	
	STAssertNotNil(connection,@"The connection object is nil !!!");
	
	NSArray *keys = [NSArray arrayWithObjects:@"URL0",@"resource0",@"URL1",@"resource1",nil];
	NSArray *values = [NSArray arrayWithObjects:@"http://subversion.bounceme.net/wephone",@"update.plist",@"http://subversion.bounceme.net/dm",@"waaa.plist",nil];
	NSDictionary *prefs = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	[connection setPreferences:prefs];
	
	//NSDictionary *preferences = [connection retrievePreferencesFromBundle];
	
	//STAssertNotNil(preferences,@"The preferences resource is nil !!!");
    
}


#endif


@end
