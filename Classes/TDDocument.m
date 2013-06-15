//
//  TDDocument.m
//  DownloadManager
//
//  Created by Daniele Poggi on 5/25/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "TDDocument.h"
#import "TDDownload.h"
#import "MKStoreManager.h"

#define kDecimalSeparatorComma @","
#define kDecimalSeparatorDot   @"."

@implementation TDDocument

@synthesize documentId, title, filename, versionNumber, version, iconname, assetsname, group;
@synthesize summary, update, preview;
@synthesize productId, currency, fee;
@synthesize matchResult;
@synthesize overallProgress;

- (id) initWithId:(NSNumber*)aDocumentId Title:(NSString*)aTitle Filename:(NSString*)aFilename {	
	if ((self = [super init])) {
		documentId = [aDocumentId retain];
		self.title = aTitle;
		self.filename = aFilename;
        matchResult = TDMatchResultCaseOk;
	}
	return self;
}

+ (TDDocument*) documentWithDescriptor:(NSDictionary*)theDict {
    
    NSNumber *documentId    = [theDict objectForKey:kDocumentId];
    NSString *title         = [theDict objectForKey:kTitle];
    NSString *filename      = [theDict objectForKey:kFilename];
    NSNumber *vid           = [theDict objectForKey:kVid];
    NSString *version       = [theDict objectForKey:kVersion];
    NSString *icon          = [theDict objectForKey:kIconname];
    NSString *assets        = [theDict objectForKey:kAssetsname];
    NSString *description   = [theDict objectForKey:kSummary];
    NSDate   *update        = [theDict objectForKey:kUpdate];
    NSString *preview       = [theDict objectForKey:kPreview];
    NSString *currency      = [theDict objectForKey:kCurrency];
    NSString *fee           = [theDict objectForKey:kFee];
    NSString *productId     = [theDict objectForKey:kProductId];
    NSNumber *group         = [theDict objectForKey:kGroup];
    
    
//    NSLog(@"Server Version: %@",theDict);		
    
    TDDocument *rem = [[[TDDocument alloc] initWithId:documentId Title:title Filename:filename] autorelease];
    [rem setVersionNumber:vid];
    [rem setVersion:version];
    [rem setIconname:icon];
    [rem setAssetsname:assets];
    [rem setSummary:description];
    [rem setUpdate:update];
    [rem setPreview:preview];
    [rem setCurrency:currency];
    [rem setFee:fee];
    [rem setProductId:productId];
    [rem setGroup:group];
    
    return rem;
}

- (BOOL) isEverythingDownloadedAndParsed{
    
    return [self isEverythingDownloaded] && [self isParsingFinished];
}

- (BOOL) isEverythingDownloaded {
    return [self isFileDownloaded] && [self isIconDownloaded] && [self isAssetsDownloaded];
}


/**
 *	@brief	controllo di presenza del parsing
 * # deprecated
 * # TO BE MOVED
 *
 *	@return	YES se il parsing è completato, NO 
 */
- (BOOL) isParsingFinished {

    
//    NSMutableArray* documentsDownloaded = nil;
//    if ([[NSUserDefaults standardUserDefaults] arrayForKey:kDocumentsDownloaded]){
//        documentsDownloaded = [NSArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:kDocumentsDownloaded]];
//        
//        for (NSString* pid in documentsDownloaded) {
//            if ([pid isEqualToString:self.productId]) {
//                return YES;
//            } 
//        }
//    }
//    return NO;
    
    // remove spaces
    NSString *filePath = [self.filename stringByReplacingOccurrencesOfString:@" " withString:@""];    
    NSString *basePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    basePath = [basePath stringByAppendingPathComponent:@"archive"];
    basePath = [basePath stringByAppendingPathComponent:filePath];    
    // replace "pdf" extension with "hindi extension"
    basePath = [basePath stringByAppendingString:@".hindi"];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:basePath];  
    if (!fileExists) {
        NSLog(@"%s WARNING: hindi archive does NOT exist at path: %@ - skipping...", __PRETTY_FUNCTION__, basePath);
    } else {
        NSLog(@"%s hindi archive exist at path: %@ - skipping...", __PRETTY_FUNCTION__, basePath);
    }
    return fileExists;
}

- (BOOL) isFileDownloaded {
    if (filename == nil) {
        NSLog(@"isFileDownloaded: ERROR filename is nil. But filename is mandatory!!!.");
        return NO;
    }
    NSString *documentPath = [TDDownloadConfig localResourceFolder];
    documentPath = [documentPath stringByAppendingPathComponent:kPDFFolderName];
    documentPath = [documentPath stringByAppendingPathComponent:filename];
    if (documentPath == nil) return NO;
//    NSLog(@"[TDDocument] checking document downloaded at path: %@",documentPath);
    BOOL fex = ([[NSFileManager defaultManager] fileExistsAtPath:documentPath]);
//    if (fex == NO) NSLog(@"[TDDocument] ... FILENAME %@ NOT EXIST",filename); else NSLog(@"[TDDocument] ... FILENAME %@ EXIST",filename);
    return fex;
}

- (BOOL) isIconDownloaded {
    
    if (iconname == nil) {
        NSLog(@"isIconDownloaded: ICON is nil. There is no need for icon.");
        return YES;
    }
    NSString *documentPath = [TDDownloadConfig localResourceFolder];
    documentPath = [documentPath stringByAppendingPathComponent:kIconFolderName];
    documentPath = [documentPath stringByAppendingPathComponent:iconname];
//    NSLog(@"[TDDocument] checking icon downloaded at path: %@",documentPath);
    BOOL fex = ([[NSFileManager defaultManager] fileExistsAtPath:documentPath]);
//    if (fex == NO) NSLog(@"[TDDocument]    NOT EXIST"); else NSLog(@"[TDDocument]     EXIST");
    return fex;
}

- (BOOL) isPreviewDownloaded {
    if (preview == nil) {
        NSLog(@"isPreviewDownloaded: PREVIEW is nil. There is no need for preview.");
        return YES;
    }
    NSString *documentPath = [TDDownloadConfig localResourceFolder];
    documentPath = [documentPath stringByAppendingPathComponent:kPreviewFolderName];
    documentPath = [documentPath stringByAppendingPathComponent:preview];
//    NSLog(@"[TDDocument] checking PREVIEW document downloaded at path: %@",documentPath);
    BOOL fex = ([[NSFileManager defaultManager] fileExistsAtPath:documentPath]);
//    if (fex == NO) NSLog(@"[TDDocument]    NOT EXIST"); else NSLog(@"[TDDocument]     EXIST");
    return fex;
}

- (BOOL) isAssetsDownloaded {
    if (assetsname == nil) {
        NSLog(@"isAssetsDownloaded: ASSETS is nil. There is no need for assets.");
        return YES;
    }
    NSString *documentPath = [TDDownloadConfig localResourceFolder];
    documentPath = [documentPath stringByAppendingPathComponent:kAssetsFolderName];
    documentPath = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", [self.filename substringWithRange:NSMakeRange(0, [self.filename length]-4)], self.assetsname]];
//    NSLog(@"[TDDocument] checking ASSETS document downloaded at path: %@",documentPath);
    BOOL fex = ([[NSFileManager defaultManager] fileExistsAtPath:documentPath]);
//    if (fex == NO) NSLog(@"[TDDocument]    NOT EXIST"); else NSLog(@"[TDDocument]     EXIST");
    return fex;
}

#pragma mark purchase support

- (BOOL) isFree {
    return nil == fee || [fee length] == 0 || [fee isEqualToString:@"0.00"]; // questo controllo va bene sia se fee è nil che se fee è @""
}

- (BOOL) isBought {
    if (productId == nil) 
        return YES;
    if ([self isFree]) 
        return YES;
    // controllo se nello standard user defaults è presente e registrato il billing del prodotto
    
}

#pragma mark document conversion

- (NSDictionary*) dictionaryDescription {
	
	NSMutableDictionary *aDict = [NSMutableDictionary dictionaryWithCapacity:4];
    
    // mandatory fields
	[aDict setObject:documentId forKey:kDocumentId];
	[aDict setObject:title forKey:kTitle];
	[aDict setObject:versionNumber forKey:kVid];
    
    // optional fields
    if (filename)   [aDict setObject:filename forKey:kFilename];
	if (version)    [aDict setObject:version forKey:kVersion];
	if (iconname)   [aDict setObject:iconname forKey:kIconname];
    if (assetsname) [aDict setObject:assetsname forKey:kAssetsname];
    if (summary)    [aDict setObject:summary forKey:kSummary];
    if (update)     [aDict setObject:update forKey:kUpdate];
    if (preview)    [aDict setObject:preview forKey:kPreview];
    if (currency)   [aDict setObject:currency forKey:kCurrency];
    if (fee)        [aDict setObject:fee forKey:kFee];
    if (productId)  [aDict setObject:productId forKey:kProductId];
    if (group)      [aDict setObject:group forKey:kGroup];
	return aDict;
}

- (NSString*) description {
	return [NSString stringWithFormat:@"%@",title];
}

- (id)copyWithZone:(NSZone *)zone {
	
	TDDocument *copy = [[TDDocument alloc] init];
	[copy setDocumentId:self.documentId];
	[copy setTitle:self.title];
	[copy setFilename:self.filename];
	[copy setVersionNumber:self.versionNumber];
	[copy setVersion:self.version];
	[copy setIconname:self.iconname];
    [copy setAssetsname:self.assetsname];
    [copy setSummary:self.summary];
    [copy setUpdate:self.update];
    [copy setPreview:self.preview];
    [copy setCurrency:self.currency];
    [copy setFee:self.fee];
    [copy setProductId:self.productId];
    [copy setGroup:self.group];
	return copy;
}

- (BOOL) isEqual:(id)object {
	return object != nil && [object isKindOfClass:[TDDocument class]] && [object documentId] != nil && [[object documentId] isEqual:[self documentId]];
}

#pragma mark - Setters

- (void) setDocumentId:(NSNumber *)aDocumentId {
    
    if ([aDocumentId isKindOfClass:[NSString class]]) {
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSNumber *formattedNumber = [formatter numberFromString:(NSString*)aDocumentId];
        if (formattedNumber) {
            documentId = formattedNumber;
            [documentId retain];
        } else
            NSLog(@"[TDDocument] setDocumentId WARNING: received string documentId, formatted the string but no number has received. NO DOCUMENT ID.");
        [formatter release];
    } else {
        
        documentId = aDocumentId;
    }
}

/*
- (void) setFee:(NSNumber *)aFee {
    
    if ([aFee isKindOfClass:[NSString class]]) {
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
//        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        
        // try to format with comma decimal separator
        [formatter setDecimalSeparator:kDecimalSeparatorComma];
        NSNumber *formattedNumber = [formatter numberFromString:(NSString*)aFee];
        
        if (formattedNumber == nil) {
            // try to format with dot decimal separator
            [formatter setDecimalSeparator:kDecimalSeparatorDot];
            formattedNumber = [formatter numberFromString:(NSString*)aFee];
        }
        
        if (formattedNumber) {
            fee = formattedNumber;
            [fee retain];
        } else
            NSLog(@"[TDDocument] setDocumentId WARNING: received string fee, formatted the string but no number has received. NO DOCUMENT FEE.");
        [formatter release];
    } else {
        
        fee = aFee;
    }
}
 */

- (void) setUpdate:(NSDate *)anUpdate {
    
    if ([anUpdate isKindOfClass:[NSString class]]) {
        
        //Parsing an RFC 3339 date-time
        
        NSDateFormatter *rfc3339DateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        NSLocale *enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
        [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
        [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'"]; //@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];        
        NSDate *formattedDate = [rfc3339DateFormatter dateFromString:(NSString*)anUpdate];
        if (formattedDate) {
            update = formattedDate;
            [update retain];
        } else
            NSLog(@"[TDDocument] setDocumentId WARNING: received string update, formatted the string but no NSDate has received. NO DOCUMENT UPDATE.");
    } else {
        
        update = anUpdate;
        [update retain];
    }
}

- (void) setVersionNumber:(NSNumber *)aVersionNumber {
    
    if ([aVersionNumber isKindOfClass:[NSString class]]) {
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSNumber *formattedNumber = [formatter numberFromString:(NSString*)aVersionNumber];
        if (formattedNumber) {
            versionNumber = formattedNumber;
            [versionNumber retain];
        } else
            NSLog(@"[TDDocument] setDocumentId WARNING: received string version number, formatted the string but no number has received. NO DOCUMENT VERSION NUMBER (vid).");
        [formatter release];
    } else {
        
        versionNumber = aVersionNumber;
        [versionNumber retain];
    }
}

- (NSString*) hash {
    
    // hashing mandatory props:
    /*
     NSNumber *documentId;
     NSString *title;
     NSNumber *versionNumber;
     */
    NSString *hs = [documentId stringValue];
    hs = [hs stringByAppendingString:title];
    hs = [hs stringByAppendingString:[versionNumber stringValue]];
    return hs;
}

@end
