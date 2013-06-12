//
//  TDDownloadConfig.h
//  DownloadManager
//
//  Created by Daniele Poggi on 26/01/12.
//  Copyright (c) 2012 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDDownloadConfig : NSObject

//! the local resource folder where the resources are stored. Default is the Library/Caches folder of the app
+ (NSString*) localResourceFolder;

@end
