//
//  InAppPurchaseManager.m
//  InAppPurchaseTest
//
//  Created by albi on 9/23/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "InAppPurchaseManager.h"

@implementation InAppPurchaseManager

@synthesize dataSource;

static InAppPurchaseManager *INSTANCE = nil;

+ (InAppPurchaseManager*)sharedInAppPurchaseManager {
	if (INSTANCE == nil) {
		INSTANCE = [[InAppPurchaseManager alloc] init];
	}
	return INSTANCE;
}

#pragma mark -
#pragma mark SKProductsRequestDelegate methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	
	TDLog(@"productsRequest Started!!");
	
    NSArray *products = response.products;
	
	TDLog(@"products: %@", [products description]);
	
    SKProduct *product = [products count] == 1 ? [[products objectAtIndex:0] retain] : nil;
    if (product)
    {
        TDLog(@"Product title: %@" , product.localizedTitle);
        TDLog(@"Product description: %@" , product.localizedDescription);
        TDLog(@"Product price: %@" , product.price);
        TDLog(@"Product id: %@" , product.productIdentifier);
    }
    
    for (NSString *invalidProductId in response.invalidProductIdentifiers) {
        TDLog(@"Invalid product id: %@" , invalidProductId);
    }
    
    // finally release the request we alloc/init’ed in requestProUpgradeProductData
    [productsRequest release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerProductsFetchedNotification object:product userInfo:nil];
}

#pragma -
#pragma Public methods
#pragma mark request methods

//
// call this method once on startup
//
- (void) loadStore {
    // restarts any purchases if they were interrupted last time the app was open
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    // get the product description (defined in early sections)
}

- (void) requestProductWithId:(NSString*)productId {
    
    // ILLEGAL ARGUMENT CHECK
    if (nil == productId || [productId length] == 0) {
        TDLog(@"requestProductWithId: ILLEGAL ARGUMENT productId is nil. Skipping...");
        return;
    }
    
    NSLog(@"%s --> %@",__PRETTY_FUNCTION__,productId);
    NSSet *productIdentifiers = [NSSet setWithObject:productId];
    productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (void) requestAutoRenewableProduct {
    NSSet *productIdentifiers = [NSSet setWithObject:kInAppPurchaseAutoRenewableProductId];
    productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
    // we will release the request object in the delegate callback
}

#pragma mark purchase methods

//
// call this before making a purchase
//
- (BOOL)canMakePurchases {
    BOOL can = [SKPaymentQueue canMakePayments];
    if (!can) {
        NSLog(@"[InAppPurchaseManager] this device cannot make purchases.");
    }
    return can;
}

- (void) purchaseProductWithId:(NSString*)productId {
    
    // ILLEGAL ARGUMENT CHECK
    if (productId == nil) {
        TDLog(@"purchaseProductWithId: ILLEGAL ARGUMENT productId is nil. Skipping...");
        return;
    }
    
    currentProductId = productId;
    
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:currentProductId];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void) registerPurchaseProductWithId:(NSString*)productId {
    // get the number of purchased documents
    NSArray *purchased = [[NSUserDefaults standardUserDefaults] arrayForKey:kDocumentsPurchased];
    NSMutableSet *mutablePurchased = nil;
    if (purchased) 
        mutablePurchased = [NSMutableSet setWithArray:purchased];
    else
        mutablePurchased = [NSMutableSet setWithCapacity:1];
    
    [mutablePurchased addObject:productId];
    [[NSUserDefaults standardUserDefaults] setObject:[mutablePurchased allObjects] forKey:kDocumentsPurchased];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) purchaseAutoRenewableProduct {
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:kInAppPurchaseAutoRenewableProductId];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma -
#pragma Purchase helpers

//
// saves a record of the transaction by storing the receipt to disk
//
- (void)recordTransaction:(SKPaymentTransaction *)transaction {
    
    if ([transaction.payment.productIdentifier isEqualToString:kInAppPurchaseAutoRenewableProductId]) {
        
        // save the transaction receipt to disk
        [[NSUserDefaults standardUserDefaults] setValue:transaction.transactionReceipt forKey:kAutoRenewableTransactionReceipt];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    } else if ([transaction.payment.productIdentifier isEqualToString:kInAppPurchaseAutoRenewableProductId]) {
        
        // save the transaction receipt to disk
//        [[NSUserDefaults standardUserDefaults] setValue:transaction.transactionReceipt forKey:k1DocumentTransactionReceipt];
//        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

//
// enable pro features
//
- (void)provideContent:(NSString *)productId {
    
    // ILLEGAL ARGUMENT CHECK
    if (productId == nil) {
        NSLog(@"provideContent: ILLEGAL ARGUMENT productId is nil.");
        return;
    }
    
    if ([productId isEqualToString:kInAppPurchaseAutoRenewableProductId]) {
    
        // enable the auto renewable features
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kIsAutoRenewablePurchased];
        [[NSUserDefaults standardUserDefaults] synchronize];
    
    } else {
        
        [self registerPurchaseProductWithId:productId];
    }
}

//
// removes the transaction from the queue and posts a notification with the transaction result
//
- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful {
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
    if (wasSuccessful) {
        // send out a notification that we’ve finished the transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionSucceededNotification object:self userInfo:userInfo];
    } else {
        // send out a notification for the failed transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionFailedNotification object:self userInfo:userInfo];
    }
}

//
// called when the transaction was successful
//
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    [self recordTransaction:transaction];
    [self provideContent:transaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
	
	TDLog(@"called when the transaction was successful");
}

//
// called when a transaction has been restored and and successfully completed
//
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    [self recordTransaction:transaction.originalTransaction];
    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
	
	TDLog(@"called when a transaction has been restored and and successfully completed");
}

//
// called when a transaction has failed
//
- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if (transaction.error.code != SKErrorPaymentCancelled) {
        // error!
        [self finishTransaction:transaction wasSuccessful:NO];
    } else {
        // this is fine, the user just cancelled, so don’t notify
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
	
	TDLog(@"called when a transaction has failed");
}

#pragma mark -
#pragma mark SKPaymentTransactionObserver methods

//
// called when the transaction status is updated
//
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchasing:
				TDLog(@"[InAppPurchaseManager] paymentQueue:updatedTransactions transaction state changed: Purchasing...");
				break;
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

@end
