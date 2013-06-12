//
//  TDRemoteIndexOperation.h
//  DownloadManager
//
//  Created by Daniele Poggi on 6/1/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDRemoteIndexDelegate.h"

@class TDDownload;

@interface TDRemoteIndexOperation : NSOperation {

	BOOL showUpdates;
	NSMutableArray *remoteIndex;
	
@private
	id <TDRemoteIndexDelegate> delegate;
	TDDownload *download;
}

@property (assign) BOOL showUpdates;
@property (assign) NSMutableArray *remoteIndex; 

@property (assign) id <TDRemoteIndexDelegate> delegate;
@property (assign) TDDownload *download;

- (id) initWithDownload:(TDDownload*)aDownload;

@end
