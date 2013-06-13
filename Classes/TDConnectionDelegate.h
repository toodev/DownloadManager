//
//  TDConnectionDelegate.h
//  DownloadManager
//
//  Created by Daniele Poggi on 5/31/10.
//  Copyright 2010 toodev. All rights reserved.
//

@protocol TDConnectionDelegate

- (void) didStartConnecting;

- (void) didFinishConnecting;

- (void) connectionNotAvailable;

@end
