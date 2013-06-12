//
//  TDPurchaseDownload.m
//  DownloadManager
//
//  Created by Daniele Poggi on 4/14/11.
//  Copyright 2011 toodev. All rights reserved.
//

#import "TDPurchaseDownload.h"
#import "TDDownloadOperation.h"
#import "InAppPurchaseManager.h"

#define BUTTON_NO 0
#define BUTTON_YES 1
#define kAlertViewPurchase 1
#define kAlertViewDownload 2

@implementation TDPurchaseDownload

@synthesize purchaseDelegate;

static TDPurchaseDownload *INSTANCE = nil;

- (id) init {
    if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:kInAppPurchaseManagerTransactionSucceededNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productTransferred:) name:kInAppPurchaseManagerProductsFetchedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:kInAppPurchaseManagerTransactionFailedNotification object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kInAppPurchaseManagerTransactionSucceededNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kInAppPurchaseManagerProductsFetchedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kInAppPurchaseManagerTransactionFailedNotification object:nil];
    [super dealloc];
}

+ (TDPurchaseDownload*) sharedInstance {
    if (INSTANCE == nil) {
        INSTANCE = [TDPurchaseDownload new];
        [INSTANCE checkAndCreateStorages];
    }
    return INSTANCE;
}

- (void) beginDownloadOfPreview:(TDDocument*)remoteDocument {
    
    if (remoteDocument.preview == nil) {
        NSLog(@"[TDPurchasePreview] document preview is nil. Skipping...");
        return;
    }
    
    // CHECK IF THE CONNECTION HAS BEEN DONE
    if (self.remoteConnectionPath == nil) {
        NSLog(@"[TDPurchasePreview] beginning connection before download of preview");
        [self chooseUpdateURL];
        [self.queue waitUntilAllOperationsAreFinished];
    }
    
    // i path
    NSString *localResourceFolder = [TDDownloadConfig localResourceFolder];
    NSString *remotePath = [self.remoteConnectionPath stringByAppendingPathComponent:kPreviewFolderName];
    remotePath = [remotePath stringByAppendingPathComponent:remoteDocument.preview];
    NSString *localPath = [localResourceFolder stringByAppendingPathComponent:kPreviewFolderName];
    localPath = [localPath stringByAppendingPathComponent:remoteDocument.preview];
    NSLog(@"%s remote path: %@", __PRETTY_FUNCTION__, remotePath);
    NSLog(@"%s local path: %@", __PRETTY_FUNCTION__, localPath);
        
    TDDownloadOperation *op = [[TDDownloadOperation alloc] initWithDownload:self document:remoteDocument remotePath:remotePath localPath:localPath];
    [op setDownloadType:DownloadTypePreview];
    [op setCommand:TDMatchResultCaseUpdate];
    [self.queue addOperation:op];
    [op release];
}

- (void) beginPurchaseOfDocument:(TDDocument*)remoteDocument {
    
    selectedDocument = remoteDocument;
    
    NSString *mex = [NSString stringWithFormat:NSLocalizedString(@"Do you want to purchase %@ ?",@"Purchase title"),remoteDocument.title];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Purchase",@"Purchase") message:mex delegate:self cancelButtonTitle:NSLocalizedString(@"No",@"No") otherButtonTitles:NSLocalizedString(@"Yes",@"Yes"),nil];
    alertView.tag = kAlertViewPurchase;
    [alertView show];
    [alertView release];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (alertView.tag) {
        case kAlertViewPurchase:
            
            switch (buttonIndex) {
                case BUTTON_YES:
                    
                    // get product id
                    if (selectedDocument == nil) {
                        NSLog(@"alertView:clickedButtonAtIndex: -> beginPurchaseOfDocument FATAL ERROR: selectedDocument is nil. Fix this. Skipping...");
                        return;
                    } else if (selectedDocument.productId == nil) {
                        NSLog(@"alertView:clickedButtonAtIndex: -> beginPurchaseOfDocument FATAL ERROR: selectedDocument has null productId. Fix this. Skipping...");
                        
                        NSString *mex = NSLocalizedString(@"Your Device cannot purchase",@"Cannot Purchase");
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Purchase",@"Cannot Purchase title") message:mex delegate:self cancelButtonTitle:NSLocalizedString(@"Help",@"Help") otherButtonTitles:NSLocalizedString(@"Cancel",@"Cancel"),nil];
                        [alertView show];
                        [alertView release];
                        
                        return;
                    }
                    
                    [[InAppPurchaseManager sharedInAppPurchaseManager] loadStore];
                    [[InAppPurchaseManager sharedInAppPurchaseManager] requestProductWithId:selectedDocument.productId];

                    
                    break;
                case BUTTON_NO:
                    NSLog(@"dismiss buy action");
                    break;
                default:
                    break;
            }
            
            break;
        case kAlertViewDownload:
            
            switch (buttonIndex) {
                case BUTTON_YES:
                    
                    if ([self performUpdate:selectedDocument]) {
                        NSLog(@"downloaded document");
                    } else {
                        NSLog(@"an error occurred while downloading document");
                    }
                    
                    break;
                case BUTTON_NO:
                    NSLog(@"dismiss buy action");
                    break;
                default:
                    break;
            }
            
        default:
            break;
    }
}

#pragma mark - In App Purchase Events

- (void) productTransferred:(NSNotification*)notification {
    
    // get the product from notification
    SKProduct *product = (SKProduct*)notification.object;
    
    if (product == nil) {
        NSLog(@"%s FATAL ERROR product is nil. Fix this. Skipping...",__PRETTY_FUNCTION__);
        return;
    }
    
    if ([[InAppPurchaseManager sharedInAppPurchaseManager] canMakePurchases]) {
        
        [[InAppPurchaseManager sharedInAppPurchaseManager] purchaseProductWithId:product.productIdentifier];
        
    } else {
        // tell the user this device cannot purchase
        NSString *mex = NSLocalizedString(@"Your Device cannot purchase",@"Cannot Purchase");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Purchase",@"Cannot Purchase title") message:mex delegate:self cancelButtonTitle:NSLocalizedString(@"Help",@"Help") otherButtonTitles:NSLocalizedString(@"Cancel",@"Cancel"),nil];
        [alertView show];
        [alertView release];
    }
}

// dopo che il prodotto è stato trasferito, se viene chiamato questo metodo vuol dire che è stato comprato
- (void) productPurchased:(NSNotification*)notification {
    
    // call purchaseDelegate
    if (purchaseDelegate)
        [(NSObject*)purchaseDelegate performSelectorOnMainThread:@selector(documentPurchased:) withObject:selectedDocument waitUntilDone:YES];
    
    
    
    NSString *mex = [NSString stringWithFormat:NSLocalizedString(@"Do you want to download %@ now ?",@"Download title"),selectedDocument.title];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download",@"Download") message:mex delegate:self cancelButtonTitle:NSLocalizedString(@"No",@"No") otherButtonTitles:NSLocalizedString(@"Yes",@"Yes"),nil];
    alertView.tag = kAlertViewDownload;
    [alertView show];
    [alertView release];
}

// dopo che il prodotto è stato trasferito, se viene chiamato questo metodo vuol dire che non è stato comprato
- (void) productPurchaseFailed:(NSNotification*)notification {
    
}

@end
