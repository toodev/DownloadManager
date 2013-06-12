//
//  TDMatchResults.h
//  DownloadManager
//
//  Created by Daniele Poggi on 5/24/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDMatchResultCase.h"
#import "TDDocument.h"

@class TDDownload;

@interface TDMatchResults : NSObject {

	//! the array of TDDocumentRemote found by matching all the remote resources with the local ones
	NSMutableSet *results;
}

@property(retain) NSMutableSet *results;

+ (TDMatchResults*) emptyResults;

- (void) addMatch:(TDDocument*)match forCase:(TDMatchResultCase)aCase;

- (void) addMatchNew:(TDDocument*)match;

- (void) addMatchUpdate:(TDDocument*)match;

- (void) addMatchDelete:(TDDocument*)match;

#pragma mark Accessory methods

- (NSUInteger) numUpdatesAvailable;

- (BOOL) isSyncronized;

@end
