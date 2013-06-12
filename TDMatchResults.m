//
//  TDMatchResults.m
//  DownloadManager
//
//  Created by Daniele Poggi on 5/24/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "TDMatchResults.h"

@implementation TDMatchResults

@synthesize results;

- (id) init
{
	self = [super init];
	if (self != nil) {
		results = [[NSMutableSet alloc] init];
	}
	return self;
}

- (void) dealloc {
    [results release];
    [super dealloc];
}

+ (TDMatchResults*) emptyResults {

	return [[[TDMatchResults alloc] init] autorelease];
}

- (void) addMatch:(TDDocument*)match forCase:(TDMatchResultCase)aCase {

	switch (aCase) {
		case TDMatchResultCaseOk:
			// nothing to do
			break;
		case TDMatchResultCaseNew:
			[self addMatchNew:match];
			break;
		case TDMatchResultCaseUpdate:
			[self addMatchUpdate:match];
			break;
		case TDMatchResultCaseDelete:
			[self addMatchDelete:match];
			break;
		default:
			// nothing to do
			break;
	}
}

- (void) addMatchNew:(TDDocument*)match {
	
	TDDocument *aDoc = [match copy];
	[aDoc setMatchResult:TDMatchResultCaseNew];
	[results addObject:aDoc];
    [aDoc release];
}

- (void) addMatchUpdate:(TDDocument*)match {

	TDDocument *aDoc = [match copy];
	[aDoc setMatchResult:TDMatchResultCaseUpdate];
	[results addObject:aDoc];
    [aDoc release];
}

- (void) addMatchDelete:(TDDocument*)match {
	
	TDDocument *aDoc = [match copy];
	// mark for delete
	[aDoc setMatchResult:TDMatchResultCaseDelete];
	// add to the set
	[results addObject:aDoc];
    [aDoc release];
}

#pragma mark Accessory methods

- (NSUInteger) numUpdatesAvailable {
	return [results count];
}

- (BOOL) isSyncronized {
	return [self numUpdatesAvailable] == 0;
}

- (NSString*) description {
	
	return [NSString stringWithFormat:@"MatchResults --> %@",[results description]];
}

@end
