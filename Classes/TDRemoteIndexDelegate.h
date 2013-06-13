//
//  TDRemoteIndexDelegate.h
//  DownloadManager
//
//  Created by Daniele Poggi on 6/1/10.
//  Copyright 2010 toodev. All rights reserved.
//

@class TDMatchResults;

@protocol TDRemoteIndexDelegate

- (void) remoteIndexDownloaded:(NSMutableArray*)remoteIndex;

- (void) updatesAvailable:(TDMatchResults*)updates;

@end
