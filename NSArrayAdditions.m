//
//  NSArrayAdditions.m
//  DownloadManager
//
//  Created by Daniele Poggi on 3/19/11.
//  Copyright 2011 toodev. All rights reserved.
//

#import "NSArrayAdditions.h"
#import "NSStringAdditions.h"
#import "DDXML.h"

@interface NSArrayAdditions (PrivateMethods)

+ (void) addChildWithName:(NSString*)name fromDict:(NSDictionary*)obj toNode:(DDXMLElement*)dict;

@end

@implementation NSArrayAdditions

+ (void) putElement:(DDXMLElement*)node inContent:(NSDictionary*)content forKey:(NSString*)key {
    @try {
        
        NSArray *values = [node elementsForName:key];
        DDXMLElement *element = [values objectAtIndex:0];
//        NSLog(@"prefix: %@ localName: %@ stringValue: %@",[element prefix], [element localName], [element stringValue]);
        [content setValue:[element stringValue] forKey:key];
    } @catch (NSException *ex) {
        NSLog(@"Exception for key %@: %@", key, ex);
    }
}

+ (NSArray*) arrayWithContentsOfXMLData:(NSData*)fileData {
    
    if (fileData == nil) {
        NSLog(@"arrayWithContentsOfXML: fileData is nil. Skipping...");
        return nil;
    }
    
    // utile per loggare il testo se non si è sicuri
//    NSString *content = [[NSString alloc] initWithBytes:[fileData bytes] length:[fileData length] encoding: NSUTF8StringEncoding];
//    NSLog(@"%@", content);
//    [content release];
    
    // this will be returned 
    NSMutableArray *arr = [NSMutableArray array];
    
    NSError *error = nil;
    DDXMLDocument *doc = [[DDXMLDocument alloc] initWithData:fileData options:0 error:&error];
    
    DDXMLElement *root = [doc rootElement];
    
    // qui hai la root contenente l'array di strutture dati.
    // occorre ciclare sule strutture dati
    // per ciascuna struttura dati occorre creare un NSDIctionary con questa struttura minima
    
    NSArray *elements = [root elementsForName:@"dict"];    
    
    @try {
        for (NSInteger i = 0; i < [elements count]; i++) {
            
            DDXMLElement *node = (DDXMLElement*)[elements objectAtIndex:i];
            
            NSMutableDictionary *content = [[NSMutableDictionary alloc] init];
            
            /* vecchio modo di inserire elementi, chiamata diretta con chiave ad hoc
            [self putElement:node inContent:content forKey:@"docId"];
            [self putElement:node inContent:content forKey:@"title"];
            [self putElement:node inContent:content forKey:@"author"];
            [self putElement:node inContent:content forKey:@"description"];
            [self putElement:node inContent:content forKey:@"vid"];
            [self putElement:node inContent:content forKey:@"filename"];
            [self putElement:node inContent:content forKey:@"icon"];
            [self putElement:node inContent:content forKey:@"assets"];
            [self putElement:node inContent:content forKey:@"fee"];
            [self putElement:node inContent:content forKey:@"currency"];
            [self putElement:node inContent:content forKey:@"update"];
            [self putElement:node inContent:content forKey:@"preview"];
            [self putElement:node inContent:content forKey:@"product_id"];
             */
            
            // nuovo modo di inserire elementi, chiave dinamica
            for (DDXMLNode *child in node.children) {
                [self putElement:node inContent:content forKey:child.name];
            }
            
            [arr addObject:content];
            [content release];
        }
        
    } @catch (NSException *ex) {
        TDLog(@"Exception while parsing XML: %@",ex);
    }
    
    return arr;
}

+ (NSArray*) arrayWithContentsOfXML:(NSString*)filename {
    
    NSData *fileData = [NSData dataWithContentsOfFile:filename];
    
    return [self arrayWithContentsOfXMLData:fileData];
}

+ (void) addChildWithName:(NSString*)name fromDict:(NSDictionary*)obj toNode:(DDXMLElement*)dict {
    
    @try {
                
        // prepare the data
        NSObject *data = [obj objectForKey:name];
        
        if (data == nil)
            return;
        
        NSString *stringVal = nil;
        
        if ([data isKindOfClass:[NSNumber class]]) {
            
            stringVal = [(NSNumber*)data stringValue];
            
        } else if ([data isKindOfClass:[NSDate class]]) {
            
            //Parsing an RFC 3339 date-time
            
            NSDateFormatter *rfc3339DateFormatter = [[[NSDateFormatter alloc] init] autorelease];
            NSLocale *enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
            [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
            [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'"]; //@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
            [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];        
            stringVal = [rfc3339DateFormatter stringFromDate:(NSDate*)data];
            
        } else if ([data isKindOfClass:[NSString class]]) {
            
            stringVal = (NSString*)data;
        } else {
            TDLog(@"[NSArrayAdditions] FATAL ERROR: kind of class is not supported yet.");
            return;
        }
        
        DDXMLNode *node = [DDXMLNode elementWithName:name stringValue:stringVal];
        [dict addChild:node];
        
    } @catch (NSException *ex) {
        NSLog(@"Exception for key %@: %@", name, ex);
    }
}

+ (BOOL) writeArray:(NSArray*)array ToXMLFile:(NSString*)filepath atomically:(BOOL)isAtomic {
    
    DDXMLElement *root = [[DDXMLElement alloc] initWithName:@"array"];

    @try {
        
        for (int i=0; i<[array count]; i++) {
            
            NSDictionary *obj = [array objectAtIndex:i];
            
            DDXMLElement *dict = [[DDXMLElement alloc] initWithName:@"dict"];
            
            /* old version with fixed keys 
            [NSArrayAdditions addChildWithName:@"docId" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"title" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"author" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"vid" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"filename" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"description" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"icon" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"assets" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"fee" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"update" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"currency" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"preview" fromDict:obj toNode:dict];
            [NSArrayAdditions addChildWithName:@"product_id" fromDict:obj toNode:dict];
            */
            
            // new version with dynamic keys
            for (NSString *key in [obj allKeys]) {
                [NSArrayAdditions addChildWithName:key fromDict:obj toNode:dict];
            }
            
            [root addChild:dict];
        }
        
    }@catch  (NSException *ex) {
        TDLog(@"Exception while creating XML tree: %@",ex);
    }
    
    DDXMLDocument *doc = [[DDXMLDocument alloc] initWithRootElement:root];
    
    NSData *xmlData = [doc XMLData];
    
    if (![xmlData writeToFile:filepath atomically:isAtomic]) {
        [doc release];
        return NO;
    }
    
    [doc release];
    return YES;
}

@end
