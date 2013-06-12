//
//  TDDownloadDelegate.h
//  DownloadManager
//
//  Created by Daniele Poggi on 5/25/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "TDDocument.h"
#import "TDMatchResultCase.h"

@protocol TDDownloadDelegate

- (void) didFinishFileDownload:(TDDocument*)document withCommand:(TDMatchResultCase)theCommand;
- (void) didFinishIconDownload:(TDDocument*)document;
- (void) didFinishPreviewDownload:(TDDocument*)document withCommand:(TDMatchResultCase)theCommand;
- (void) downloadFailed:(TDDocument*)document withError:(NSError*)error;

@optional

- (void) didStartDownload:(TDDocument*)document;

- (void) fileDownloading:(TDDocument*)document progress:(float)progress;
- (void) assetDownloading:(TDDocument*)document progress:(float)progress;
- (void) iconDownloading:(TDDocument*)document progress:(float)progress;
- (void) previewDownloading:(TDDocument*)document progress:(float)progress;

- (void) downloadsExecuting:(NSUInteger)numOfDownloads;

- (void) downloadIconFailed:(TDDocument*)document withError:(NSError*)error;
- (void) downloadPreviewFailed:(TDDocument*)document withError:(NSError*)error;

@end
