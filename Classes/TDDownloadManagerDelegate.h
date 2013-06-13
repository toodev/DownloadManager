//
//  TDDownloadManagerDelegate.h
//  DownloadManager
//
//  Created by Daniele Poggi on 6/25/11.
//  Copyright 2011 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TDDownloadManagerDelegate <NSObject>

- (void) didStartDownload:(TDDocument*)document;
- (void) downloadOverallProgress:(TDDocument*)document;
- (void) didFinishDownload:(TDDocument*)document;

@end
