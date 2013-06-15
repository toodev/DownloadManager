//
//  TDDownloadOperation.m
//  DownloadManager
//
//  Created by Daniele Poggi on 5/25/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "TDDownloadOperation.h"

@implementation TDDownloadOperation

@synthesize delegate, downloadType, command, download, remotePath, localPath, remoteDocument;

- (id) initWithDownload:(TDDownload*)aDownload {
	
	if ((self = [super init])) {
        
        // default download type is icon
        downloadType = DownloadTypeIcon;
		self.download = aDownload;
		self.delegate = download;
	}
	return self;
}

- (id) initWithDownload:(TDDownload *)aDownload document:(TDDocument*)document remotePath:(NSString *)aRemotePath localPath:(NSString *)aLocalPath {
    if ((self = [super init])) {
        // default download type is icon
        downloadType = DownloadTypeIcon;
		download = aDownload;
		delegate = download;
        remoteDocument = document;
        self.remotePath = aRemotePath;
        self.localPath = aLocalPath;
    }
    return self;
}

- (BOOL) isConcurrent { return YES; }

- (BOOL) isExecuting { 
    return downloading;
}

- (BOOL) isFinished { 
    if (!downloading) NSLog(@"%s FINISHED DOWNLOAD",__PRETTY_FUNCTION__);
    return !downloading;
}

- (void) dealloc {
    [connection release];
    [receivedData release];
    [response release];
    [localPath release];
    [remotePath release];
    [super dealloc];
}

- (void) notifyError:(NSError*)error {
    
    switch (downloadType) {
        case DownloadTypeIcon:
            if (delegate) [delegate downloadIconFailed:remoteDocument withError:error];
            break;
        case DownloadTypePreview:
            if (delegate) [delegate downloadPreviewFailed:remoteDocument withError:error];
            break;
            
        case DownloadTypeFile:
            if (delegate) [delegate downloadFailed:remoteDocument withError:error];
            break;
        default:
            break;
    }
}

- (void) main {
    
    // ILLEGAL ARGUMENT CHECKS
    
    if (remoteDocument == nil) {
        NSLog(@"%s remoteDocument is nil. Download Operation skipping...",__PRETTY_FUNCTION__);
        return;
    }
    
    if (downloadType == DownloadTypeFile && remoteDocument.filename == nil) {
        NSLog(@"%s remoteDocument has nil filename. Download Operation skipping...",__PRETTY_FUNCTION__);
        return;
    }
    
    if (downloadType == DownloadTypeIcon && remoteDocument.iconname == nil) {
        NSLog(@"%s remoteDocument has nil iconname. Download Operation skipping...",__PRETTY_FUNCTION__);
        return;
    }
    
    if (downloadType == DownloadTypePreview && remoteDocument.preview == nil) {
        NSLog(@"%s remoteDocument has nil preview. Download Operation skipping...",__PRETTY_FUNCTION__);
        return;
    }
    
    if (localPath == nil) {
        NSLog(@"%s localPath is nil. Download operation skipping...",__PRETTY_FUNCTION__);
        return;
    }
    
    // OLD DOWNLOAD
    /*
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            
    if (delegate) [delegate didStartDownload:remoteDocument];
    
    // THE REAL DOWNLOAD
    
    // inject the change of downloadTable in DM
    if (downloadType == DownloadTypeFile || downloadType == DownloadTypePreview)
        [download setDownloadStatus:DownloadStatusDownloading toDocument:remoteDocument];
    
    NSURL *documentURL = [NSURL URLWithString:remotePath];
    
    if (documentURL == nil) {
        if (delegate) [delegate downloadIconFailed:remoteDocument withError:nil];
        return;
    }
    
    // Create the request.
    NSURLRequest *request = [NSURLRequest requestWithURL:documentURL
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:kDownloadTimeoutInterval];
    
    // create the connection with the request
    // and start loading the data
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
    
    [pool release];
     */
    
    NSString *rPath = [remotePath stringByReplacingOccurrencesOfString:@"http:/www" withString:@"http://www"];
    if (![rPath isEqualToString:remotePath]) {
        // gestione memoria
        [remotePath release];
        remotePath = [rPath retain];
    }
    NSURL *remoteDocumentURL = [NSURL URLWithString:remotePath];
    
    if (nil == remoteDocumentURL) {
        [self notifyError:[NSError errorWithDomain:@"com.toodev.dm.TDDownloadOperation" code:1 userInfo:nil]];
        return;
    }
    
    ASIHTTPRequest *downloadRequest = [ASIHTTPRequest requestWithURL:remoteDocumentURL];
    downloadRequest.downloadDestinationPath = localPath;
    downloadRequest.delegate = self;
    downloadRequest.downloadProgressDelegate = self;
    [downloadRequest startAsynchronous];
}

- (void) start {
	
	// Always check for cancellation before launching the task.
	if ([self isCancelled])
	{
		// Must move the operation to the finished state if it is canceled.
		[self willChangeValueForKey:@"isFinished"];
        
        downloading = NO;
        
		[self didChangeValueForKey:@"isFinished"];
		return;
	}
	
	// If the operation is not canceled, begin executing the task.
	[self willChangeValueForKey:@"isExecuting"];
    		
	//[NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
	[self performSelectorOnMainThread:@selector(main) withObject:nil waitUntilDone:NO];
	
	downloading = YES;

	[self didChangeValueForKey:@"isExecuting"];
	
	NSLog(@"----------------------> Start method called by the queue object for download: %@.",[remoteDocument title]);		
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    downloading = NO;
 
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void) finalizeDownload {
	
	NSLog(@"%s Succeeded! Resource \"%@\" received %d bytes of data",__PRETTY_FUNCTION__,remoteDocument.title,[receivedData length]);
		
	// FROM THIS POINT THE OLD RESOURCE IS UPDATED
	// store the path						
    NSLog(@"%s writing data to file: %@",__PRETTY_FUNCTION__,localPath);
    NSError *error;
	if(![receivedData writeToFile:localPath options:NSDataWritingAtomic error:&error]) {
        NSLog(@"%s Error saving the resource",__PRETTY_FUNCTION__);
	}	
    
    // injection of final steps before calling delegate
    [self finalSteps];
	
	// notify who uses the delegate that the downloading is complete
    switch (downloadType) {
        case DownloadTypeIcon:
            if (delegate) 
                [(NSObject*)delegate performSelectorOnMainThread:@selector(didFinishIconDownload:) withObject:remoteDocument waitUntilDone:YES];
            break;
        case DownloadTypePreview:
            if (delegate) [delegate didFinishPreviewDownload:remoteDocument withCommand:command];
            break;
        case DownloadTypeFile:
        case DownloadTypeAsset:
            if (delegate) [delegate didFinishFileDownload:remoteDocument withCommand:command];
            break;
        default:
            break;
    }	
    
    [self completeOperation];
}

#pragma mark -
#pragma mark NSURLConnection implementation

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)aResponse {
	// This method is called when the server has determined that it
	// has enough information to create the NSURLResponse.
	
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)aResponse;
	NSInteger statusCode = [httpResponse statusCode];
	if( statusCode == 200 ) {
		NSUInteger contentSize = [httpResponse expectedContentLength] > 0 ? [httpResponse expectedContentLength] : 0;
		
        // It can be called multiple times, for example in the case of a
        // redirect, so each time we reset the data.
        response = aResponse;
        [response retain];
        receivedData = [[NSMutableData alloc] initWithCapacity:contentSize];
        
	} else {
		NSString* statusError  = [NSString stringWithFormat:NSLocalizedString(@"HTTP Error: %ld", nil), statusCode];
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:statusError forKey:NSLocalizedDescriptionKey];
		NSError *error = [[NSError alloc] initWithDomain:@"ToodevHindiDownloadOperationDomain"
											code:statusCode
										userInfo:userInfo];
		[self notifyError:error];
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	
	NSLog(@"didReceiveAuthenticationChallenge");
	
	if ([challenge previousFailureCount] == 0 && [challenge proposedCredential] == nil) {
		[[challenge sender] useCredential:[download credential] forAuthenticationChallenge:challenge];
	} else if ([challenge proposedCredential] != nil) {
		NSLog(@"received credential: %@",[challenge proposedCredential]);
	} else {
		NSLog(@"cancelling the credential matching");
		[[challenge sender] cancelAuthenticationChallenge:challenge];
	}
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
	NSLog(@"didCancelAuthenticationChallenge");
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	
    long long expectedDim = [response expectedContentLength];
    
    if (expectedDim != NSURLResponseUnknownLength) {
        
        // Append the new data to receivedData.
        [receivedData appendData:data];
        
        // evaluate progress
        float progress = [receivedData length] / (float)expectedDim;
        
        switch (downloadType) {
            case DownloadTypeIcon:
                if (delegate && [(NSObject*) delegate respondsToSelector:@selector(iconDownloading:progress:)]) 
                    [delegate iconDownloading:remoteDocument progress:progress];
                break;
            case DownloadTypePreview:
                if (delegate && [(NSObject*) delegate respondsToSelector:@selector(previewDownloading:progress:)]) 
                    [delegate previewDownloading:remoteDocument progress:progress];
                break;
            case DownloadTypeFile:
                if (delegate && [(NSObject*) delegate respondsToSelector:@selector(fileDownloading:progress:)]) 
                    [delegate fileDownloading:remoteDocument progress:progress];
                break;
            case DownloadTypeAsset:
                if (delegate && [(NSObject*) delegate respondsToSelector:@selector(assetDownloading:progress:)]) 
                    [delegate assetDownloading:remoteDocument progress:progress];
                break;
            default:
                break;
        }
    } else {
        NSLog(@"cannot determine content length - bytes received: %i",receivedData.length);
    }
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	
    // inform the user
    NSLog(@"Connection failed with error: %@",[error description]);
    NSLog(@"more info:  %@",[error userInfo]);
    // delegate
    if (delegate)
        [delegate downloadFailed:remoteDocument withError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    
    [self finalizeDownload];
}

// final operations to be executed after download (Override this for future implementations)
- (void) finalSteps {
    
}

#pragma mark - ASIHTTPRequestDelegate

- (void)requestStarted:(ASIHTTPRequest *)request {
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    // injection of final steps before calling delegate
    [self finalSteps];
	
	// notify who uses the delegate that the downloading is complete
    switch (downloadType) {
        case DownloadTypeIcon:
            if (delegate)
                [(NSObject*)delegate performSelectorOnMainThread:@selector(didFinishIconDownload:) withObject:remoteDocument waitUntilDone:YES];
            break;
        case DownloadTypePreview:
            if (delegate) [delegate didFinishPreviewDownload:remoteDocument withCommand:command];
            break;
        case DownloadTypeFile:
        case DownloadTypeAsset:
            if (delegate) [delegate didFinishFileDownload:remoteDocument withCommand:command];
            break;
        default:
            break;
    }
    [self completeOperation];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    NSLog(@"%s ERROR: %@",__PRETTY_FUNCTION__,request.error);
    // delegate
    if (delegate)
        [delegate downloadFailed:remoteDocument withError:request.error];
}

#pragma mark - ASIProgressDelegate

- (void)setProgress:(float)progress {
    switch (downloadType) {
        case DownloadTypeIcon:
            if (delegate && [(NSObject*) delegate respondsToSelector:@selector(iconDownloading:progress:)])
                [delegate iconDownloading:remoteDocument progress:progress];
            break;
        case DownloadTypePreview:
            if (delegate && [(NSObject*) delegate respondsToSelector:@selector(previewDownloading:progress:)])
                [delegate previewDownloading:remoteDocument progress:progress];
            break;
        case DownloadTypeFile:
            if (delegate && [(NSObject*) delegate respondsToSelector:@selector(fileDownloading:progress:)])
                [delegate fileDownloading:remoteDocument progress:progress];
            break;
        case DownloadTypeAsset:
            if (delegate && [(NSObject*) delegate respondsToSelector:@selector(assetDownloading:progress:)])
                [delegate assetDownloading:remoteDocument progress:progress];
            break;
        default:
            break;
    }
}

@end
