//
//  TDDeleteOperation.h
//  DownloadManager
//
//  Created by Daniele Poggi on 6/14/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDDownload.h"

@interface TDDeleteOperation : NSOperation {

	TDDownload *download;
	@private
	id <TDDownloadDelegate> delegate;
	TDDocument *document;
}

@property (nonatomic, copy) TDDocument *document;
@property (nonatomic, assign) TDDownload *download;
@property (nonatomic, assign) id <TDDownloadDelegate> delegate;

- (id) initWithDownload:(TDDownload*)aDownload;

@end
