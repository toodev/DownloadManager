//
//  TDConnectionOperation.h
//  DownloadManager
//
//  Created by Daniele Poggi on 5/31/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDConnectionDelegate.h"

@class TDDownload;

@interface TDConnectionOperation : NSOperation {

	@private
	id <TDConnectionDelegate> delegate;
	TDDownload *download;
    float defaultRequestTimeout;
}

@property (assign) id <TDConnectionDelegate> delegate;
@property (assign) TDDownload *download;
@property (assign) float defaultRequestTimeout;

- (id) initWithDownload:(TDDownload*)aDownload;

@end
