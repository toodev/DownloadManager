//
//  MatchesTest.m
//  DownloadManager
//
//  Created by Daniele Poggi on 5/24/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "MatchesTest.h"
#import "TDDownload.h"
#import "TDMatchResults.h"

@implementation MatchesTest

#if USE_APPLICATION_UNIT_TEST     // all code under test is in the iPhone Application

- (void) testAppDelegate {
    
    id yourApplicationDelegate = [[UIApplication sharedApplication] delegate];
    STAssertNotNil(yourApplicationDelegate, @"UIApplication failed to find the AppDelegate");
    
}

#else                            // all code under test must be linked into the Unit Test bundle

- (void) testMath {
    
    TDDownload *download = [[TDDownload alloc] init];
			
	NSArray *keys = [NSArray arrayWithObjects:@"vid",@"filename",@"docId",@"title",@"author",nil];
	NSArray *values = [NSArray arrayWithObjects:[NSNumber numberWithInt:1],@"pdfdocument.pdf",[NSNumber numberWithInt:52671237],@"Title",@"Author",nil];
	NSDictionary *aDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	[download setDocumentIndex:[NSArray arrayWithObject:aDict]];
	
	NSArray *keys1 = [NSArray arrayWithObjects:@"vid",@"filename",@"docId",@"title",@"author",nil];
	NSArray *values1 = [NSArray arrayWithObjects:[NSNumber numberWithInt:2],@"pdfdocument.pdf",[NSNumber numberWithInt:52671237],@"Title",@"Author",nil];
	NSDictionary *aDict2 = [NSDictionary dictionaryWithObjects:values1 forKeys:keys1];
	[download setUpdatedDocumentIndex:[NSArray arrayWithObject:aDict2]];
	
	//TDMatchResults *matches = [download compareLocalWithLastUpdate];
	
	//STAssertNotNil(matches,@"compareLocalWithLastUpdate must not return nil !!!");
	
	//[download performUpdate:matches];
	
	/*
	
	NSMutableSet *matchesSet = [matches results];
	
	STAssertNotNil(matchesSet,@"the mutable set inside the TDMatchResults must be not nil !!!");	
 
	NSArray *matchesArray = [matchesSet allObjects];
	
	NSUInteger count = [matchesArray count];
	
	//STAssertTrue(count > 0,@"There should be at least 1 update, but nothing is found !!!");
	
	NSDictionary *match = nil;
	
	if (count > 0) {
		
		TDDocument *match = [matchesArray objectAtIndex:0];
		
		STAssertNotNil(match,@"there should be 1 update available...");
		
		BOOL val = [match updateDoc]; 
				
		STAssertEquals(val,1,@"the resource is not marked for update !!!"); 
		
	}
	
	NSString *filename = [match objectForKey:@"filename"];
	
	if (match) STAssertNotNil(filename,@"The filename should be present in the dictionary");
	*/
}


#endif


@end
