//
//  TDDeleteOperation.m
//  DownloadManager
//
//  Created by Daniele Poggi on 6/14/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "TDDeleteOperation.h"
#import "TDDownload.h"

@implementation TDDeleteOperation

@synthesize delegate, download, document;

- (id) initWithDownload:(TDDownload*)aDownload {
	
	self = [super init];
	if (self != nil) {
		self.download = aDownload;
		self.delegate = download;
	}
	return self;
}

- (void) dealloc {
    
    [document release];
    [super dealloc];
}

- (void) main {
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	// INITIAL CHECK-UP OF RESOURCES
	if (document == nil) {
		NSLog(@"----> WARNING: an attempt of DELETING a nil resource has been done. skipping...");
		if (delegate) [delegate didFinishFileDownload:document withCommand:TDMatchResultCaseError];
		[pool release];
		return;
	}
	
	@try {
		NSError **error = nil;
		NSString *path = nil;
        
        NSString *localResourceFolder = [TDDownloadConfig localResourceFolder];
		
		// REMOVE RESOURCE OPERATION
		if ([document filename] != nil) {
			path = [localResourceFolder stringByAppendingPathComponent:[document filename]];
			NSLog(@"Removing the file: %@",path);
			// remove the file
			if (![[download fileManager] removeItemAtPath:path error:error]) {
				NSLog(@"Cannot remote the file for the document: %@",[document description]);
			}
		}
		// END
		
		// REMOVE ICON RESOURCE OPERATION
		if ([document iconname] != nil) {
			path = [localResourceFolder stringByAppendingPathComponent:[document iconname]];
			NSLog(@"Removing the icon file: %@",path);
			if (![[download fileManager] removeItemAtPath:path error:error]) {
				NSLog(@"Cannot remote the icon file for the document: %@",[document description]);
			}	
		}
		// END
		
		// REMOVE DESCRIPTOR OPERATION
		NSUInteger index = [[download documentIndex] indexOfObject:document];
		if (NSNotFound != index) {
			[[download documentIndex] removeObjectAtIndex:index];
		} else {
			NSLog(@"----> WARNING: descriptor for file: %@ has not been found while DELETING. skipping...",[document filename]);
		}
		//END
		
		// SERIALIZATION OPERATION
		[download serializeMyIndex];
		
		if (delegate) [delegate didFinishFileDownload:document withCommand:TDMatchResultCaseDelete];
		
	} @catch (NSException *ex) {
		if (delegate) [delegate didFinishFileDownload:document withCommand:TDMatchResultCaseError];
	}		
	
	[pool release];
}

@end
