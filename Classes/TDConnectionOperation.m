//
//  TDConnectionOperation.m
//  DownloadManager
//
//  Created by Daniele Poggi on 5/31/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "TDConnectionOperation.h"
#import "TDDownload.h"

@implementation TDConnectionOperation

@synthesize delegate, download, defaultRequestTimeout;;

- (id) initWithDownload:(TDDownload*)aDownload {
	
	self = [super init];
	if (self != nil) {
		self.download = aDownload;
		self.delegate = download;
        defaultRequestTimeout = 10;
	}
	return self;
}

/*!
 @method      connectionTest
 @abstract   tests the connection towards the XML-RPC server.
 @discussion can be used to avoid all Wrapper methods if the server is unreachable.
 @result     YES if the connection is available, NO otherwise.
 */
- (BOOL) connectionTest:(NSString*)server {
    
	// ILLEGAL ARGUMENT
	if (server == nil) {
		NSLog(@"[TDConnectionOperation] connectionTest: the server string is nil. cannot connect.");
		return NO;
	}
	
	// test "server" string can be a NSURL
	NSURL *testURL = [[NSURL alloc] initWithString:server];	
	if (testURL == nil) {
		NSLog(@"[TDConnectionOperation] connectionTest: the server URL is nil. cannot connect.");
        [testURL release];
		return NO;
	}
    
	// test URL connection
	NSURLRequest *testRequest = [[NSURLRequest alloc] initWithURL:testURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:self.defaultRequestTimeout];
	if (![NSURLConnection canHandleRequest:testRequest]) {
		NSLog(@"[TDConnectionOperation] connectionTest: the wrapper CANNOT handle a request to the server. cannot connect.");
        
        // release the tests
        [testRequest release];
        [testURL release];
        return NO;
	}
	
	// release the tests
	[testRequest release];
	[testURL release];
	
	NSLog(@"[TDConnectionOperation] connectionTest: OK");
	return YES;
}

- (void) main {
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if (delegate) [delegate didStartConnecting];
	
	if ([download remoteConnectionPath] && [download remoteConnectionURL]) {
		NSLog(@"ConnectionOperation will quit since the connection has already been established."); 
		if (delegate) [delegate didFinishConnecting];			
		[pool release];
		return;
	}
	
	if ([download preferences] == nil) {
		[download setConnectionStatus:kCONN_UNAVAILABLE]; 
		NSLog(@"Preferences not found. Connection operation is skipping..."); 
		if (delegate) [delegate connectionNotAvailable];
		[pool release];
		return;
	}		
	
	NSString *theURL  = nil, *theResource = nil;
	NSInteger urlIdx = 0, resIdx = 0;

	while ((theURL = [[download preferences] objectForKey:[NSString stringWithFormat:@"%@%i",kPREF_URL,urlIdx++]])) {
		while ((theResource = [[download preferences] objectForKey:[NSString stringWithFormat:@"%@%i",kPREF_RES,resIdx++]])) {
			
            NSString *connString = nil;
			// USERNAME & PASSWORD here
			NSString *username = [[download preferences] objectForKey:[NSString stringWithFormat:@"%@%i",kPREF_USERNAME,urlIdx-1]];
			NSString *password = [[download preferences] objectForKey:[NSString stringWithFormat:@"%@%i",kPREF_PASSWORD,urlIdx-1]];
			if (username && password) {
				NSString *paths = [NSString pathWithComponents:[NSArray arrayWithObjects:theURL,theResource,nil]];
				NSString *paths2 = [paths stringByReplacingOccurrencesOfString:@"http:/" withString:@""];				   
				connString = [NSString stringWithFormat:@"http://%@:%@@%@",username,password,paths2];
				NSLog(@"connString: %@",connString);
			} else {
				// NO USERNAME AND-OR PASSWORD FOUND: ASSUMING NT NEEDED
				connString = [NSString pathWithComponents:[NSArray arrayWithObjects:theURL,theResource,nil]];
				NSLog(@"creating the connection without credentials: %@",connString);
			}
            
            // Connection test
			if ([self connectionTest:connString]) {
				[download setRemoteConnectionPath:theURL];
				[download setRemoteConnectionURL:[NSURL URLWithString:connString]];
				if (username && password) {
					[download setCredential:[NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone]];
				}
				
				NSLog(@"found VALID connection URL.");
				download.connectionStatus = kCONN_AVAILABLE;
				
				if (delegate) [delegate didFinishConnecting];	
				
				// release the pool
				[pool release];	
				
				return;
				
			} else {
				NSLog(@"INVALID connection URL: %@ \n\tNext...",[theURL description]);
			}
		}	
		resIdx = 0;
	}
	
	if ([download remoteConnectionURL] == nil) {
		[download setConnectionStatus:kCONN_UNAVAILABLE]; 
		NSLog(@"RemoteConnectionPath not available."); 
		if (delegate) [delegate connectionNotAvailable];
		[pool release];
		return;
	}
	
	if (delegate) [delegate didFinishConnecting];	
	
	[pool release];
}

@end
