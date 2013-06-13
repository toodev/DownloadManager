//
//  LocalResourcesTest.m
//  DownloadManager
//
//  Created by Daniele Poggi on 29/05/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "LocalResourcesTest.h"


@implementation LocalResourcesTest

#if USE_APPLICATION_UNIT_TEST     // all code under test is in the iPhone Application

- (void) testAppDelegate {
    
    id yourApplicationDelegate = [[UIApplication sharedApplication] delegate];
    STAssertNotNil(yourApplicationDelegate, @"UIApplication failed to find the AppDelegate");
    
}

#else                           // all code under test must be linked into the Unit Test bundle

- (void) testMath {
    
    TDDownload *download = [[TDDownload alloc] init];
	
	NSArray *keys = [NSArray arrayWithObjects:@"vid",@"filename",@"docId",@"title",@"author",nil];
	NSArray *values = [NSArray arrayWithObjects:[NSNumber numberWithInt:1],@"pdfdocument.pdf",[NSNumber numberWithInt:52671237],@"Title",@"Author",nil];
	NSDictionary *aDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	[download setDocumentIndex:[[NSArray alloc] initWithObjects:aDict,nil]];
	
	TDDocument *aDoc = [[download documentIndex] objectAtIndex:0];
	
	STAssertNotNil(aDoc,@"The document is nil !!!");
	
	/*
	
	NSString *path = [aDoc path];
	
	STAssertNotNil(path,@"The document path is nil !!!");
	
	
	
	TDDocument *aDocCopy = [aDoc copy];
	
	STAssertNotNil(aDocCopy,@"The document copy is nil !!!");
	
	NSDictionary *aDocDescription = [aDocCopy dictionaryDescription];
	
	STAssertNotNil(aDocDescription,@"The document copy description is nil !!!");
	 
	 */
    
}


#endif


@end
