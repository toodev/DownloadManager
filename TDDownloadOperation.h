//
//  TDDownloadOperation.h
//  DownloadManager
//
//  Created by Daniele Poggi on 5/25/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDMatchResultCase.h"
#import "TDDownload.h"
#import "ASIHTTPRequest.h"

@interface TDDownloadOperation : NSOperation <ASIHTTPRequestDelegate, ASIProgressDelegate> {
    
    DownloadType downloadType;
	
	//! remote resource path used to download the NSData
	NSString *remotePath;
    
    //! local path used to store the file
    NSString *localPath;
    
    //! the document to download
	TDDocument *remoteDocument;
    
    //! the match result command to apply (if available)
    TDMatchResultCase command;
    
	@private
    BOOL downloading;
	id <TDDownloadDelegate> delegate;
	TDDownload* download;
	NSURLConnection *connection;
	NSURLResponse *response;
	NSMutableData *receivedData;
}

@property(nonatomic, assign) DownloadType downloadType;

@property(nonatomic, retain) NSString *remotePath;
@property(nonatomic, retain) NSString *localPath;
@property(nonatomic, assign) TDDocument *remoteDocument;

@property(assign) TDMatchResultCase command;

@property(assign) id <TDDownloadDelegate> delegate;
@property(assign) TDDownload* download;

- (id) initWithDownload:(TDDownload *)aDownload document:(TDDocument*)document remotePath:(NSString *)remotePath localPath:(NSString *)localPath;

// final operations to be executed after download (Override this for future implementations)
- (void) finalSteps;

@end

