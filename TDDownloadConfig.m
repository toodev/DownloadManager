//
//  TDDownloadConfig.m
//  DownloadManager
//
//  Created by Daniele Poggi on 26/01/12.
//  Copyright (c) 2012 toodev. All rights reserved.
//

#import "TDDownloadConfig.h"

@implementation TDDownloadConfig

+ (NSString*) localResourceFolder {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

@end
