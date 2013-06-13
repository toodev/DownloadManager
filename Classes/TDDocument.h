//
//  TDDocument.h
//  DownloadManager
//
//  Created by Daniele Poggi on 5/25/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDMatchResultCase.h"
#import "TDDownloadConfig.h"

// DICTIONARY DESCRIPTION KEYS
// mandatory
#define kDocumentId @"docId"
#define kTitle      @"title"
#define kVid        @"vid"
// optional
#define kFilename   @"filename"
#define kVersion    @"version"
#define kIconname   @"icon"
#define kAssetsname @"assets"
#define kSummary    @"description"
#define kUpdate     @"update"
#define kPreview    @"preview"
#define kCurrency   @"currency"
#define kFee        @"fee"
#define kProductId  @"product_id"
#define kGroup      @"group"

@interface TDDocument : NSObject <NSCopying> {
    
    // MANDATORY FIELDS
	NSNumber *documentId;
	NSString *title;
	NSString *filename;		
	NSNumber *versionNumber;
    
    // OPTIONAL FIELDS
    NSString *iconname;
    NSString *version;
    NSString *summary;
    NSDate   *update;
    NSString *preview;
    NSString *assetsname;
    
    // IN APP PURCHASE FIELDS
    NSString *productId;
    NSString *currency;
    NSString *fee;
    
    NSNumber *group;
    
    // the result of matching local resource with remote one
    TDMatchResultCase matchResult;
    
    //! while downloading the document file, icon and asset, this is the overall progress
    //! computed by TDDOwnloadManagerDelegate
    float overallProgress;
}

@property (nonatomic, copy, readwrite) NSNumber *documentId;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *filename;
@property (nonatomic, copy, readwrite) NSString *version;
@property (nonatomic, copy, readwrite) NSString *iconname;
@property (nonatomic, copy, readwrite) NSString *assetsname;
@property (nonatomic, copy, readwrite) NSNumber *versionNumber;

@property (nonatomic, copy, readwrite) NSString *summary;
@property (nonatomic, copy, readwrite) NSDate *update;
@property (nonatomic, copy, readwrite) NSString *preview;

@property (nonatomic, copy, readwrite) NSString *productId;
@property (nonatomic, copy, readwrite) NSString *currency;
@property (nonatomic, copy, readwrite) NSString *fee;

@property (nonatomic, copy, readwrite) NSNumber *group;

@property(nonatomic, assign) TDMatchResultCase matchResult;

@property(nonatomic, assign) float overallProgress;

// document status
- (BOOL) isEverythingDownloaded;
- (BOOL) isFileDownloaded;
- (BOOL) isIconDownloaded;
- (BOOL) isPreviewDownloaded;
- (BOOL) isAssetsDownloaded;
- (BOOL) isParsingFinished;
- (BOOL) isEverythingDownloadedAndParsed;

// constructor
- (id) initWithId:(NSNumber*)aDocumentId Title:(NSString*)aTitle Filename:(NSString*)aFilename;

// auto-released constructor
+ (TDDocument*) documentWithDescriptor:(NSDictionary*)descriptor;
// serialization-prone method
- (NSDictionary*) dictionaryDescription;
// unique identifier
- (NSString*) hash;

// PURCHASE
- (BOOL) isFree;
- (BOOL) isBought;

@end
