//
//  TDPurchaseDownloadDelegate.h
//  DownloadManager
//
//  Created by Daniele Poggi on 7/7/11.
//  Copyright 2011 toodev. All rights reserved.
//

#import "TDDocument.h"

@protocol TDPurchaseDownloadDelegate <NSObject>

- (void) documentPurchased:(TDDocument*)document;

@end
