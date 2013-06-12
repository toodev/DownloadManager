//
//  TDPurchaseDownload.h
//  DownloadManager
//
//  Created by Daniele Poggi on 4/14/11.
//  Copyright 2011 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TDDownload.h"
#import "TDPurchaseDownloadDelegate.h"

@interface TDPurchaseDownload : TDDownload <UIAlertViewDelegate> {
    
    TDDocument *selectedDocument;
    
    id<TDPurchaseDownloadDelegate> purchaseDelegate;
}

@property (nonatomic, assign) id<TDPurchaseDownloadDelegate> purchaseDelegate;

+ (TDPurchaseDownload*) sharedInstance;

- (void) beginDownloadOfPreview:(TDDocument*)remoteDocument;
- (void) beginPurchaseOfDocument:(TDDocument*)remoteDocument;

- (void) productPurchased:(NSNotification*)notification;
- (void) productTransferred:(NSNotification*)notification;
- (void) productPurchaseFailed:(NSNotification*)notification;

@end
