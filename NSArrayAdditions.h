//
//  NSArrayAdditions.h
//  DownloadManager
//
//  Created by Daniele Poggi on 3/19/11.
//  Copyright 2011 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArrayAdditions : NSObject {
    
}

/*
 * an XML extension that allows the building of an NSArray from XML serialization
 * and a serialization towards XML
 */

+ (NSArray*) arrayWithContentsOfXML:(NSString*)filename;
+ (NSArray*) arrayWithContentsOfXMLData:(NSData*)fileData;

+ (BOOL) writeArray:(NSArray*)array ToXMLFile:(NSString*)filename atomically:(BOOL)isAtomic;

@end
