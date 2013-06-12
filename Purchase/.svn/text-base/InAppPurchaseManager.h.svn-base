//
//  InAppPurchaseManager.h
//  InAppPurchaseTest
//
//  Created by albi on 9/23/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "InAppPurchaseDataSource.h"

#define kInAppPurchaseManagerProductsFetchedNotification @"kInAppPurchaseManagerProductsFetchedNotification"
#define kInAppPurchaseManagerTransactionFailedNotification @"kInAppPurchaseManagerTransactionFailedNotification"
#define kInAppPurchaseManagerTransactionSucceededNotification @"kInAppPurchaseManagerTransactionSucceededNotification"

// receipt validation
#define kSandboxReceiptURL    @"https://sandbox.itunes.apple.com/verifyReceipt"
#define kReceiptValidationURL @"https://buy.itunes.apple.com/verifyReceipt"

// product identifiers
//#define kInAppPurchase1DocumentProductId @"com.disney.topolino.000A"
#define kInAppPurchaseAutoRenewableProductId @"com.toodev.hindi.1month"

// standard user default keys
#define kIsAutoRenewablePurchased @"isAutoRenewablePurchased"
#define kAutoRenewableTransactionReceipt @"autoRenewableTransactionReceipt"

#define kDocumentsPurchased @"documentsPurchased"
#define kDocumentsDownloaded @"documentsDownloaded"

@interface InAppPurchaseManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
	
    //! the product data source
    id<InAppPurchaseDataSource> dataSource;
    
    //! current purchased product identifier
    NSString *currentProductId;
    
    //! current product request
    SKProductsRequest *productsRequest;	
}

@property (nonatomic, assign) id<InAppPurchaseDataSource> dataSource;

+ (InAppPurchaseManager*)sharedInAppPurchaseManager;

// public methods
- (void) loadStore;
- (BOOL) canMakePurchases;

// requests
- (void) requestProductWithId:(NSString*)productId;
- (void) requestAutoRenewableProduct;

// purchase
- (void) purchaseProductWithId:(NSString*)productId;
- (void) registerPurchaseProductWithId:(NSString*)productId;
- (void) purchaseAutoRenewableProduct;

@end
