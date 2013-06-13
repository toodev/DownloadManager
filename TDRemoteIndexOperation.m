//
//  TDRemoteIndexOperation.m
//  DownloadManager
//
//  Created by Daniele Poggi on 6/1/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "TDRemoteIndexOperation.h"
#import "TDDownload.h"
#import "NSArrayAdditions.h"

@implementation TDRemoteIndexOperation

@synthesize delegate, download, showUpdates, remoteIndex;

- (id) initWithDownload:(TDDownload*)aDownload {
	
	self = [super init];
	if (self != nil) {
		self.download = aDownload;
		self.delegate = download;
	}
	return self;
}

- (void) main {
		
	if ([download remoteConnectionURL] == nil) {
		TDLog(@"The connection URL is nil !!! Remote index will not be loaded.");
		return;
	}	
    
    // detect the kind of remote index
    NSArray *dictArray = nil;
    
    switch (download.updateFileType) {
        case Plist: {
            dictArray = [NSArray arrayWithContentsOfURL:[download remoteConnectionURL]];            
        }
        break;
        case XML: {
            NSData *remoteIndexData = [NSData dataWithContentsOfURL:[download remoteConnectionURL]];
            dictArray = [NSArrayAdditions arrayWithContentsOfXMLData:remoteIndexData];
        }
        break;
            
        default:
            TDLog(@"a valid update file type has not been found.");
            break;
    }
    
    // check if at this point the array is nil
    if (dictArray == nil) {
        TDLog(@"The remote index is not loaded correctly.");		
    }
	
	NSMutableArray *updatedDocumentIndex = [[NSMutableArray alloc] init];
	
	for (NSDictionary *theDict in dictArray) {		
        
        TDDocument *rem = [TDDocument documentWithDescriptor:theDict];
        
		// finally add to the remote index
		[updatedDocumentIndex addObject:rem];		
	}
	
	if (showUpdates) {
		// invoke the compareLocalWithLastUpdate automatically
		TDMatchResults *updates = [download compareLocalWithRemote];
        if (delegate) [delegate updatesAvailable:updates];
	}
	
	if (delegate) 
        [(NSObject*)delegate performSelectorOnMainThread:@selector(remoteIndexDownloaded:) withObject:updatedDocumentIndex waitUntilDone:YES];
    
    [updatedDocumentIndex release];
}

@end
