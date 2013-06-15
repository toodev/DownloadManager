//
//  TDDownload.m
//  DownloadManager
//
//  Created by Daniele Poggi on 5/24/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import "TDDownload.h"
#import "TDDownloadOperation.h"
#import "TDDownloadUnzipOperation.h"
#import "TDDeleteOperation.h"
#import "TDRemoteIndexOperation.h"
#import "TDDownloadConfig.h"
#import "NSArrayAdditions.h"

@implementation TDDownload

@synthesize updateFileType, localUpdateFileType, downloadMode;
@synthesize pdfFolder, iconFolder, previewFolder, assetFolder;
@synthesize connectionStatus, fileManager, currentSort;
@synthesize connectionDelegate, remoteIndexDelegate, downloadDelegate, downloadManagerDelegate;
@synthesize preferences=_preferences, descriptionPath, documentIndex, updatedDocumentIndex, remoteConnectionPath, remoteConnectionURL;
@synthesize credential, queue, connectionOperation;
@synthesize downloadTable;

#pragma mark -
#pragma mark Initialization

- (id) init {
	self = [super init];
	if (self != nil) {
        updateFileType = XML;
        localUpdateFileType = Binary;
        downloadMode = InAppPurchaseMode;
        
		fileManager = [NSFileManager defaultManager];
		documentIndex = [[NSMutableArray alloc] init];
		updatedDocumentIndex = [[NSMutableArray alloc] init];
        
        NSString *documentPath = [TDDownloadConfig localResourceFolder];
        
        // prepare the local index path (maybe doesn't exist yet)
        if (updateFileType == Plist)
            self.descriptionPath = [documentPath stringByAppendingPathComponent:kUPDATE_FILE_NAME_PLIST];
        else
            self.descriptionPath = [documentPath stringByAppendingPathComponent:kUPDATE_FILE_NAME_XML];
        
		// initialize the queue operation manager
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:5];
        
        // prepare download table
        downloadTable = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id) initWithPreferences:(NSDictionary*)aPreferences {
	
	if ((self = [self init])) {
        _preferences = aPreferences;
        // prepare storages
        [self checkAndCreateStorages];
    }
	return self;
}

//static TDDownload *INSTANCE = nil;

/*
 + (id) sharedInstance {
 
 if (INSTANCE == nil) {
 NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
 NSString *prefDictionaryPath;
 if ((prefDictionaryPath = [thisBundle pathForResource:@"Preferences" ofType:@"plist"]))  {
 // when completed, it is the developer's responsibility to release theDictionary
 NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:prefDictionaryPath];
 INSTANCE = [[TDDownload alloc] initWithPreferences:preferences];
 [preferences release];
 } else {
 NSLog(@"[TDDownload] sharedInstance ERROR: Preferences.plist file not found. return nil...");
 return nil;
 }
 }
 
 return INSTANCE;
 }
 */

- (void) checkAndCreateStorages {
    
    NSString *localResourceFolder = [TDDownloadConfig localResourceFolder];
    if (nil == localResourceFolder) {
        NSLog(@"%s FATAL ERROR: local resource folder is nil. aborting...",__PRETTY_FUNCTION__);
        abort();
    }
    // prepare local folders
    NSError *error;
    // "pdf" folder
    self.pdfFolder = [localResourceFolder stringByAppendingPathComponent:kPDFFolderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:pdfFolder]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:pdfFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"preConnectionStuff: FATAL ERROR while creating folder %@ with error: %@ ... ABORTING APP ...",pdfFolder, [error userInfo]);
            abort();
        }
    }
    // "icon" folder
    self.iconFolder = [localResourceFolder stringByAppendingPathComponent:kIconFolderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:iconFolder]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:iconFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"preConnectionStuff: FATAL ERROR while creating folder %@ with error: %@ ... ABORTING APP ...",iconFolder, [error userInfo]);
            abort();
        }
    }
    // "preview" folder
    self.previewFolder = [localResourceFolder stringByAppendingPathComponent:kPreviewFolderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:previewFolder]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:previewFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"preConnectionStuff: FATAL ERROR while creating folder %@ with error: %@ ... ABORTING APP ...",previewFolder, [error userInfo]);
            abort();
        }
    }
    // "asset" folder
    self.assetFolder = [localResourceFolder stringByAppendingPathComponent:kAssetsFolderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:assetFolder]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:assetFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"preConnectionStuff: FATAL ERROR while creating folder %@ with error: %@ ... ABORTING APP ...",assetFolder, [error userInfo]);
            abort();
        }
    }
}

#pragma mark -
#pragma mark Connection

- (void) preConnectionStuff {
    
    // choose the url for the server
	[self chooseUpdateURL];
}

- (NSDictionary*) preferences {
	
	if (_preferences) return _preferences;
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Preferences.plist" ofType:nil];
    if (path == nil) {
        NSLog(@"[TDDownload] SEVERE ERROR: Preferences.plist is missing from Bundle. Please create a new Preferences file before continue.");
    }
	_preferences = [[NSDictionary alloc] initWithContentsOfFile:path];
	return _preferences;
}

- (void) chooseUpdateURL {
	
	if (remoteConnectionURL && remoteConnectionPath) return;
	
	// use connection operation
	self.connectionOperation = [[TDConnectionOperation alloc] initWithDownload:self];
	[connectionOperation setQueuePriority:NSOperationQueuePriorityNormal];
	[queue addOperation:connectionOperation];
}

#pragma mark -
#pragma mark MyIndex

- (NSMutableArray*) loadLibraryIndexFromIndex:(NSMutableArray*)myIndex {
    
    NSMutableArray *array = [NSMutableArray new];
    
    [myIndex enumerateObjectsUsingBlock:^(TDDocument *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isBought] && [obj isFileDownloaded]) {
            [array addObject:obj];
        }
    }];
    
    return array;
}


- (NSMutableArray*) loadMyIndex {
	
	if (documentIndex == nil) {
		NSLog(@"DocumentIndex is nil !!!");
		self.documentIndex = [[NSMutableArray alloc] init];
	}
	
	[documentIndex removeAllObjects];
	
	NSArray *myArray = nil;
    
    switch (localUpdateFileType) {
        case Plist:
            myArray = [NSArray arrayWithContentsOfFile:descriptionPath];
            break;
        case XML:
            myArray = [NSArrayAdditions arrayWithContentsOfXML:descriptionPath];
        case Binary: {
            NSError *error;
            NSData *myData = [NSData dataWithContentsOfFile:descriptionPath options:NSDataReadingUncached error:&error];
            if (myData == nil) {
                NSLog(@"Fatal error while loading my local index at path: %@ error: %@",descriptionPath,[error userInfo]);
                return documentIndex;
            }
            NSPropertyListFormat format;
            myArray = [NSPropertyListSerialization propertyListWithData:myData options:0 format:&format error:&error];
            if (myArray == nil) {
                NSLog(@"Fatal error while de-serializing my local index at path: %@ error: %@",descriptionPath,[error userInfo]);
                return documentIndex;
            }
        }
        default:
            break;
    }
	
	if (myArray == nil) {
		NSLog(@"There is no serialization of the local document index to load. Skipping...");
		return documentIndex;
	}
	
	for (NSDictionary *theDict in myArray) {
		TDDocument *aDoc = [TDDocument documentWithDescriptor:theDict];
        // retain the document in the documentIndex
		[documentIndex addObject:aDoc];
	}
	return documentIndex;
}

- (BOOL) checkMyIndex {
	
	return YES;
}

- (void) serializeMyIndex {
	
	NSMutableArray *myArray = [[NSMutableArray alloc] init];
	
	for (TDDocument *aDoc in documentIndex) {
		NSDictionary *aDict = [aDoc dictionaryDescription];
		[myArray addObject:aDict];
	}
    
    switch (localUpdateFileType) {
        case Plist: {
            if(![myArray writeToFile:descriptionPath atomically:YES]) {
                NSLog(@"Cannot write the local index at the description path: %@",descriptionPath);
            } else {
                NSLog(@"Local index serialized.");
            }
        }
            break;
        case XML: {
            if(![NSArrayAdditions writeArray:myArray ToXMLFile:descriptionPath atomically:YES]) {
                NSLog(@"Cannot write the local index to the XML description path: %@",descriptionPath);
            } else {
                NSLog(@"Local index serialized.");
            }
        }
        case Binary: {
            NSError *error;
            NSData *data = [NSPropertyListSerialization dataWithPropertyList:myArray format:NSPropertyListBinaryFormat_v1_0 options:NSPropertyListMutableContainersAndLeaves error:&error];
            if (data == nil) {
                NSLog(@"Fatal error while saving my index: %@",[error userInfo]);
                return;
            }
            if (![data writeToFile:descriptionPath options:NSDataWritingFileProtectionComplete error:&error]) {
                NSLog(@"Fatal error while writing my index to path: %@ : %@",descriptionPath,[error userInfo]);
            } else {
                NSLog(@"Local index serialized");
            }
        }
        default:
            break;
    }
    
    [myArray release];
}

- (void) replaceMyIndexWithLastUpdate {
    
	[self replaceMyIndexWithUpdate:updatedDocumentIndex];
}

- (void) replaceMyIndexWithUpdate:(NSArray*)updatedIndex {
    
    // ILLEGAL ARGUMENT CHECKS
    
	if(updatedIndex == nil) {
		NSLog(@"The dictionary with the updated resources must not be nil");
        return;
	}
    
    if([updatedIndex count] == 0) {
		NSLog(@"The dictionary with the updated resources must not be empty");
        return;
	}
    
	NSLog(@"Write the new description at path: %@",descriptionPath);
	[documentIndex removeAllObjects];
    [documentIndex addObjectsFromArray:updatedIndex];
 	
    [self serializeMyIndex];
}

- (NSDictionary*) documentIndexForDocument:(TDDocument*)aDocument {
	
	NSNumber *docID;
	for (NSDictionary *theDict in documentIndex) {
		docID = [theDict objectForKey:@"docId"];
		if ([docID isEqualToNumber:[aDocument documentId]]) return theDict;
	}
	return nil;
	
}

- (BOOL) isIndexEqual:(TDDocument*)dict1 withIndex:(TDDocument*)dict2 {
	
	NSNumber *dict1ID = [dict1 documentId];
	if (dict1ID == nil) {
		NSLog(@"The document ID cannot be found in %@",dict1);
		return NO;
	}
	NSNumber *dict2ID = [dict2 documentId];
	if (dict2ID == nil) {
		NSLog(@"The document ID cannot be found in %@",dict2);
		return NO;
	}
	
	if ([dict1ID isEqualToNumber:dict2ID]) {
		NSLog(@"dict1 ID: %@ <---> dict2 ID: %@",dict1ID,dict2ID);
		NSLog(@"Found local description that matches resources %@",[dict2 description]);
		return YES;
	}
	return NO;
}

- (TDDocument*) isLocallyPresent:(TDDocument*)remoteDoc inArray:(NSArray*)anArray {
	
	for (TDDocument *checkDict in anArray) {
		if ([self isIndexEqual:remoteDoc withIndex:checkDict]) return checkDict;
	}
	return nil;
}

#pragma mark -
#pragma mark CompleteIndex

- (void) loadCompleteIndex {
	
	[self loadCompleteIndexShowUpdates:NO];
}

- (void) loadCompleteIndexShowUpdates:(BOOL)updatesAvailable {
	
	// check connectionOperation, which is a dependency for the remote index
	if (connectionOperation == nil) {
        [self preConnectionStuff];
    }
	
	TDRemoteIndexOperation *op = [[TDRemoteIndexOperation alloc] initWithDownload:self];
	[op setShowUpdates:updatesAvailable];
	[op setQueuePriority:NSOperationQueuePriorityNormal];
	[op addDependency:connectionOperation];
	[queue addOperation:op];
    [op release];
    
    // wait until this operation is finished
    //    [queue waitUntilAllOperationsAreFinished];
}

#pragma mark -
#pragma mark Matches

/*
 * local selector used to identify if a dictionary description of a document indicates that is older than another one compatible
 */
- (BOOL) isOlder:(TDDocument*)first Then:(TDDocument*)second {
	
	NSNumber *firstVer, *secondVer;
	
	firstVer  = [first versionNumber];
	secondVer = [second versionNumber];
	
	NSLog(@"first  version number: %@",[firstVer description]);
	NSLog(@"second version number: %@",[secondVer description]);
	
	if (firstVer == nil) {
		NSLog(@"The version of the FIRST dictionary is not present !!!");
		return NO;
	}
	if (secondVer == nil) {
		NSLog(@"The version of the SECOND dictionary is not present !!!");
		return NO;
	}
	
	NSComparisonResult result = [firstVer compare:secondVer];
	
	return (NSOrderedSame == result) ? NO : YES;
}

- (TDMatchResultCase) processForUpdate:(TDDocument*)remoteDocument inLocalIndex:(NSArray*)anIndex {
    
	if (remoteDocument == nil) {
		NSLog(@"Aborting update: the remoteDocument cannot be nil !!!");
		return TDMatchResultCaseError;
	}
	
	TDDocument *match;
	// check if the file for the description is present
    NSString *localResourceFolder = [TDDownloadConfig localResourceFolder];
	NSString *path = [localResourceFolder stringByAppendingPathComponent:[remoteDocument filename]];
	BOOL fileIsPresent = [fileManager fileExistsAtPath:path];
	if (fileIsPresent) NSLog(@"Local resource found at path: %@",path);
	else NSLog(@"Local resource for remote document %@ has NOT been found.",[remoteDocument filename]);
    
	if ((match = [self isLocallyPresent:remoteDocument inArray:anIndex])) {
		if ([self isOlder:match Then:remoteDocument]) {
			// common case: the matched resource is older then the updated one.... UPDATE
			[remoteDocument setMatchResult:TDMatchResultCaseUpdate];
			return TDMatchResultCaseUpdate;
		} else if (!fileIsPresent) {
			// the descriptor is present but the file is missing... UPDATE
			[remoteDocument setMatchResult:TDMatchResultCaseUpdate];
			return TDMatchResultCaseUpdate;
		} else {
			// the remote is synchronized. do nothing.
		}
	} else {
		// if not present, the new resource will be added as NEW
		[remoteDocument setMatchResult:TDMatchResultCaseNew];
		return TDMatchResultCaseNew;
	}
	
	return TDMatchResultCaseOk;
}

- (TDMatchResultCase) processForDelete:(TDDocument*)localDocument inRemoteIndex:(NSArray*)anIndex {
	
	// search for the local document in the remote index
	// if the local is not found, mark for DELETE, mark OK otherwise.
	
	if (NSNotFound == [anIndex indexOfObject:localDocument]) {
		NSLog(@"processForDelete: \"%@\" NOT FOUND IN REMOTE INDEX --> DELETE",[localDocument description]);
		return TDMatchResultCaseDelete;
	}
	NSLog(@"processForDelete: \"%@\" FOUND IN REMOTE INDEX --> KEEP",[localDocument description]);
	return TDMatchResultCaseOk;
}

- (TDMatchResults*) compareLocalWithRemote {
	
	TDMatchResults *results = [TDMatchResults emptyResults];
	
    //	if ([[queue operations] count] > 0) {
    //		NSLog(@"Requesting Sync while operations are being executed. compareLocalWithLastUpdate will be skipped...");
    //		return results;
    //	}
	
	// first call connection test
	[self preConnectionStuff];
	
	if (connectionStatus == kCONN_UNAVAILABLE) {
		NSLog(@"Connection unavailable, abort operation.");
		return results;
	}
	
	if (updatedDocumentIndex == nil) {
		NSLog(@"updatedDocumentIndex is nil !!!");
		return results;
	}
	
	// COPY THE LOCAL AND REMOTE INDEX TO A NEW MEMORY SPACE
	NSArray *documentIndexCopy = [[NSArray alloc] initWithArray:documentIndex copyItems:YES];
	NSArray *updatedDocumentIndexCopy = [[NSArray alloc] initWithArray:updatedDocumentIndex copyItems:YES];
	
	// NEW - UPDATE checks
	for(TDDocument *remoteDoc in updatedDocumentIndexCopy) {
		TDMatchResultCase matchCase = [self processForUpdate:remoteDoc inLocalIndex:documentIndexCopy];
		[results addMatch:remoteDoc forCase:matchCase];
	}
	// DELETE checks
	for(TDDocument *localDoc in documentIndexCopy) {
		TDMatchResultCase matchCase = [self processForDelete:localDoc inRemoteIndex:updatedDocumentIndexCopy];
		if (matchCase == TDMatchResultCaseDelete) {
			// create a remote copy of the local document descriptor
			TDDocument *remoteDoc = [localDoc copy];
			// add the remote doc WILL be marked for delete in the match results
			[results addMatch:remoteDoc forCase:matchCase];
            // release
            [remoteDoc release];
		}
	}
    
    [updatedDocumentIndexCopy release];
    [documentIndexCopy release];
    
	return results;
}

#pragma mark -
#pragma mark Complete Update requests

- (BOOL) performCompleteUpdate:(TDMatchResults*)updates {
	
	return [self performCompleteUpdate:updates WithSort:TDSortNone];
}

- (BOOL) performCompleteUpdate:(TDMatchResults*)updates WithSort:(TDSort)aSort {
	
    //	if ([[queue operations] count] > 0) {
    //		NSLog(@"Requesting Complete Update while operations are being executed. performCompleteUpdate will be skipped...");
    //		NSLog(@"operations: %@",[[queue operations] description]);
    //		return NO;
    //	}
	
	self.currentSort = aSort;
	
	// first call connection test
	// BUG: connection test should be called only by the compareLocal operation
	// because there is always a compare before an update operation
	// [self preConnectionStuff];
	
	//TODO use the error
	NSError **error = nil;
	
	for (TDDocument *aDoc in [updates results]) {
		
		NSLog(@"Complete update of : %@",[aDoc description]);
		[self performUpdate:aDoc];
	}
	
	return error == nil ? YES : NO;
}

#pragma mark -
#pragma mark Operations and queues

- (BOOL) performUpdate:(TDDocument*)updatedDocument {
	
	return [self performUpdate:updatedDocument withMatchResult:[updatedDocument matchResult]];
}

- (BOOL) performUpdate:(TDDocument*)updatedDocument withMatchResult:(TDMatchResultCase)matchCase {
	
	// check if updatedDocument exists
	if (updatedDocument == nil) {
        NSLog(@"Aborting performUpdate: because updatedDocument is nil !!!");
        return NO;
	}
	
	// check if the title exists
	if ([updatedDocument title] == nil) {
        NSLog(@"Aborting performUpdate: because updatedDocument TITLE is nil !!!");
        return NO;
	}
    
    // CHECK IF DOCUMENT IS PRESENT
    BOOL documentDownloaded = [updatedDocument isEverythingDownloadedAndParsed];
    
    //TESTS FOR ABORTING UPDATE (because is not needed)
    if (documentDownloaded && TDMatchResultCaseOk == matchCase) {
		NSLog(@"Aborting UPDATE because is not needed. File already present and last version of index.");
		return NO;
	}
    
    // CHECK IF THE CONNECTION HAS BEEN DONE
    if (remoteConnectionPath == nil) {
        NSLog(@"[TDDownload] beginning connection before download");
        [self chooseUpdateURL];
        [queue waitUntilAllOperationsAreFinished];
    }
	
	// CONTINUE THE UPDATE
    
	if (TDMatchResultCaseNew == matchCase || TDMatchResultCaseUpdate == matchCase || documentDownloaded == NO) {
		NSLog(@"Preparing NEW or UPDATE operation");
        
        // DOWNLOAD THE PDF
        //  [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        // prepare local and remote paths
        NSString *rp = [remoteConnectionPath stringByAppendingPathComponent:kPDFFolderName];
        rp = [rp stringByAppendingPathComponent:updatedDocument.filename];
        NSString *lp = [pdfFolder stringByAppendingPathComponent:updatedDocument.filename];
        
		// prepare the download operation
		TDDownloadOperation *op = [[TDDownloadOperation alloc] initWithDownload:self document:updatedDocument remotePath:rp localPath:lp];
        
        // queue priority adaptable to the 5 download slot available
        if (queue.operationCount <= 1)
            [op setQueuePriority:NSOperationQueuePriorityVeryHigh];
        else if (queue.operationCount <= 3)
            [op setQueuePriority:NSOperationQueuePriorityHigh];
        else
            [op setQueuePriority:NSOperationQueuePriorityLow];
        
        [op setDownloadType:DownloadTypeFile];
		[op setCommand:matchCase];
        [queue addOperation:op];
        [op release];
        
        // DOWNLOAD THE ASSET ZIP
        if (updatedDocument.assetsname) {
            
            // prepare local and remote paths
            NSString *ra = [remoteConnectionPath stringByAppendingPathComponent:kAssetsFolderName];
            ra = [ra stringByAppendingPathComponent:updatedDocument.assetsname];
            NSString *la = [assetFolder stringByAppendingPathComponent:[updatedDocument.filename substringWithRange:NSMakeRange(0, [updatedDocument.filename length]-4)]];
            NSError *error;
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:la]) {
                if (![[NSFileManager defaultManager] createDirectoryAtPath:la withIntermediateDirectories:YES attributes:nil error:&error]) {
                    NSLog(@"preConnectionStuff: FATAL ERROR while creating folder %@ with error: %@ ... ABORTING APP ...",la, [error userInfo]);
                    abort();
                }
            }
            
            //updatedDocument.assetsname = [NSString stringWithFormat:@"%@/%@", updatedDocument.title, updatedDocument.assetsname];
            la = [la stringByAppendingPathComponent:updatedDocument.assetsname];
            
            // prepare the download operation
            TDDownloadUnzipOperation *op2 = [[TDDownloadUnzipOperation alloc] initWithDownload:self document:updatedDocument remotePath:ra localPath:la];
            
            // download
            [op2 setDownloadType:DownloadTypeAsset];
            [op2 setCommand:matchCase];
            // set the Assets file to be executed after the PDF file download
            [op2 addDependency:op];
            [queue addOperation:op2];
            [op2 release];
        }
        
	} else {
		// prepare the delete operation
		NSLog(@"Preparing DELETE operation");
		TDDeleteOperation *op = [[TDDeleteOperation alloc] initWithDownload:self];
		[op setDocument:updatedDocument];
        [queue addOperation:op];
        [op release];
	}
    
	NSLog(@"ADDED an operation in queue.");
	// finally process the operation in the queue
	
	
	return YES;
}

#pragma mark Download

- (BOOL) isDownloadingDocument:(TDDocument*)document {
    NSNumber *status = [downloadTable objectForKey:document.documentId];
    if (status) {
        return [status intValue] == DownloadStatusDownloading;
    } else {
        NSLog(@"[TDDownload] isDownloadingDocument PRESETTING \"available\" mode for document: %@",[document description]);
        [self setDownloadStatus:DownloadStatusAvailable toDocument:document];
        return NO;
    }
}

- (void) setDownloadStatus:(DownloadStatus)downloadStatus toDocument:(TDDocument*)document {
    NSLog(@"[TDDownload] setDownloadStatus: %i toDocument: %@",downloadStatus,[document description]);
    [downloadTable setObject:[NSNumber numberWithInt:downloadStatus] forKey:document.documentId];
}

#pragma mark -
#pragma mark CRUD operations on TDDocument

- (void) deleteFiles:(TDDocument*)anIndex {
    // remove the document
    if (anIndex.filename) {
        if (![fileManager removeItemAtPath:[pdfFolder stringByAppendingPathComponent:anIndex.filename] error:NULL]) {
            NSLog(@"Cannot remove the file for the document: %@",[anIndex description]);
        }
    }
	// remove the icon
	if (anIndex.iconname) {
		if (![fileManager removeItemAtPath:[iconFolder stringByAppendingPathComponent:anIndex.iconname] error:NULL]) {
			NSLog(@"Cannot remove the icon for the document: %@",[anIndex description]);
		}
	}
    // remove any asset
    if (anIndex.assetsname) {
		if (![fileManager removeItemAtPath:[assetFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", anIndex.title, anIndex.assetsname]] error:NULL]) {
			NSLog(@"Cannot remove the asset for the document: %@",[anIndex description]);
		}
	}
    // remove preview
    if (anIndex.preview) {
        if (![fileManager removeItemAtPath:[previewFolder stringByAppendingPathComponent:anIndex.preview] error:NULL]) {
			NSLog(@"Cannot remote the preview for the document: %@",[anIndex description]);
		}
    }
    
}

- (void) deleteIndex:(TDDocument*)anIndex {
	
	[self archiveIndex:anIndex];
	// remove the descriptor
	[documentIndex removeObjectAtIndex:[documentIndex indexOfObject:anIndex]];
	// serialize the descriptor
	[self serializeMyIndex];
}

- (void) archiveIndex:(TDDocument*)anIndex {
	
	// remove the document
    if (anIndex.filename) {
        if (![fileManager removeItemAtPath:[pdfFolder stringByAppendingPathComponent:anIndex.filename] error:NULL]) {
            NSLog(@"Cannot remote the file for the document: %@",[anIndex description]);
        }
    }
	// remove the icon
	if (anIndex.iconname) {
		if (![fileManager removeItemAtPath:[iconFolder stringByAppendingPathComponent:anIndex.iconname] error:NULL]) {
			NSLog(@"Cannot remote the icon for the document: %@",[anIndex description]);
		}
	}
    // remove any asset
    if (anIndex.assetsname) {
		if (![fileManager removeItemAtPath:[assetFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", anIndex.title, anIndex.assetsname]] error:NULL]) {
			NSLog(@"Cannot remote the asset for the document: %@",[anIndex description]);
		}
	}
    // remove preview
    if (anIndex.preview) {
        if (![fileManager removeItemAtPath:[previewFolder stringByAppendingPathComponent:anIndex.preview] error:NULL]) {
			NSLog(@"Cannot remote the preview for the document: %@",[anIndex description]);
		}
    }
    
	// serialize the descriptor
	[self serializeMyIndex];
}

#pragma mark Destructors

- (void) dealloc {
	
	// serialize the local index
	[self serializeMyIndex];
	[_preferences release];
	[descriptionPath release];
	[documentIndex release];
	[updatedDocumentIndex release];
	[remoteConnectionPath release];
	
	// stop all downloads
	[queue cancelAllOperations];
	[queue release];
	[super dealloc];
}

#pragma mark -
#pragma mark Utilities

NSInteger titleSort(id doc1, id doc2, void *reverse) {
    
    NSString *v1 = [(TDDocument*)doc1 title];
    NSString *v2 = [(TDDocument*)doc2 title];
    
    if ((NSInteger *)reverse == NO) {
        return [v2 localizedCaseInsensitiveCompare:v1];
    }
    return [v1 localizedCaseInsensitiveCompare:v2];
}

NSInteger docIdSort(id doc1, id doc2, void *reverse) {
    
    int v1 = [[(TDDocument*)doc1 documentId] intValue];
    int v2 = [[(TDDocument*)doc2 documentId] intValue];
    
    if((NSInteger *)reverse == NO) {
        if (v1 > v2) return NSOrderedAscending;
        else if (v1 < v2)return NSOrderedDescending;
        else return NSOrderedSame;
    } else {
        if (v1 < v2) return NSOrderedAscending;
        else if (v1 > v2) return NSOrderedDescending;
        else return NSOrderedSame;
    }
    
}

NSInteger dateSort (id doc1, id doc2, void *reverse) {
    
    NSDate *v1 = [(TDDocument*)doc1 update];
    NSDate *v2 = [(TDDocument*)doc1 update];
    
    if((NSInteger *)reverse == NO) {
        if ([v1 laterDate:v2] == v1) return NSOrderedAscending;
        else if ([v1 earlierDate:v2] == v1)return NSOrderedDescending;
        else return NSOrderedSame;
    } else {
        if ([v1 earlierDate:v2] == v1) return NSOrderedAscending;
        else if ([v1 laterDate:v2] == v1) return NSOrderedDescending;
        else return NSOrderedSame;
    }
    
}

NSInteger groupSort (id doc1, id doc2, void *reverse) {
    
    int v1 = [[(TDDocument*)doc1 group] intValue];
    int v2 = [[(TDDocument*)doc1 group] intValue];
    
    if((NSInteger *)reverse == NO) {
        if (v1 > v2) return NSOrderedAscending;
        else if (v1 < v2)return NSOrderedDescending;
        else return NSOrderedSame;
    } else {
        if (v1 < v2) return NSOrderedAscending;
        else if (v1 > v2) return NSOrderedDescending;
        else return NSOrderedSame;
    }
    
}

- (void) sortSelector {
	
	// documentIndex è l'array in cui fare il sort
	// currentSort è l'enum che dice quale sort è stato richiesto
	// ad oggi esiste il sort
	// TDSortNone    che indica di non fare il sort
	// TDSortByTitle e TDSortByDocId
	NSLog(@"Requested to SORT the local index with sort type: %i",currentSort);
	if (currentSort == TDSortNone) {
		NSLog(@"There is no sort rule. skipping...");
		return;
	}
	
	int ascending = NO;
	
	switch(currentSort) {
        case TDSortByTitleAscending:
            ascending = YES;
            [documentIndex sortUsingFunction:titleSort context:&ascending];
            break;
        case TDSortByDocIdAscending:
            ascending = YES;
            [documentIndex sortUsingFunction:docIdSort context:&ascending];
            break;
        case TDSortByTitleDescending:
            [documentIndex sortUsingFunction:titleSort context:&ascending];
            break;
        case TDSortByDocIdDescending:
            [documentIndex sortUsingFunction:docIdSort context:&ascending];
            break;
        case TDSortByDateAscending:
            ascending = YES;
            [documentIndex sortUsingFunction:dateSort context:&ascending];
            break;
        case TDSortByDateDescending:
            [documentIndex sortUsingFunction:dateSort context:&ascending];
            break;
        case TDSortByGroupAscending: {
            ascending = YES;
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"group" ascending:ascending];
            NSArray *descriptiors = [NSArray arrayWithObjects:sort, nil];
            [documentIndex sortUsingDescriptors:descriptiors];
        }
            break;
        case TDSortByGroupDescending: {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"group" ascending:ascending];
            NSArray *descriptiors = [NSArray arrayWithObjects:sort, nil];
            [documentIndex sortUsingDescriptors:descriptiors];
        }
            break;
        default:
            break;
	}
    
	NSLog(@"The sorted documentIndex description: %@",[documentIndex description]);
	
    //    documentIndex = [sortedArray mutableCopy];
	
	NSLog(@"SORT completed succesfully.");
}

#pragma mark -
#pragma mark TDConnectionDelegate standard implementation

- (void) didStartConnecting {
	NSLog(@"------------>ConnectionOperation: start connecting<------------");
	
	// bounce to external delegate
	if (connectionDelegate) [connectionDelegate didStartConnecting];
}

- (void) didFinishConnecting {
	NSLog(@"------------>ConnectionOperation: finished connecting<------------");
    
	// bounce to external delegate
	if (connectionDelegate) [connectionDelegate didFinishConnecting];
}

- (void) connectionNotAvailable {
	NSLog(@"------------>ConnectionOperation: connection not available<------------");
	
	// bounce to external delegate
	if (connectionDelegate) [connectionDelegate connectionNotAvailable];
}

#pragma mark -
#pragma mark TDRemoteIndexDelegate standard implementation

- (void) remoteIndexDownloaded:(NSMutableArray*)remoteIndex {
    
	NSLog(@"remote index downloaded");
	[updatedDocumentIndex removeAllObjects];
	[updatedDocumentIndex addObjectsFromArray:remoteIndex];
	NSLog(@"The new remote index description: \n %@",[updatedDocumentIndex description]);
    
    // if in app purchase download the icons
    if (downloadMode == InAppPurchaseMode) {
        
        NSLog(@"[TDDownload] download mode is IN APP PURCHASE: starting download of icons.......");
        
        for (TDDocument *document in remoteIndex) {
            
            if (document.iconname && [document isIconDownloaded] == NO) {
                
                NSLog(@"[RemoteIndexDownloaded] download ICON needed for document %@",document);
                
                // prepare remotePath and localPath
                NSString *rp = [remoteConnectionPath stringByAppendingPathComponent:kIconFolderName];
                rp = [rp stringByAppendingPathComponent:document.iconname];
                NSString *lp = [iconFolder stringByAppendingPathComponent:document.iconname];
                
                TDDownloadOperation *op = [[TDDownloadOperation alloc] initWithDownload:self document:document remotePath:rp localPath:lp];
                [op setDownloadType:DownloadTypeIcon];
                [op setCommand:TDMatchResultCaseUpdate];
                [queue addOperation:op];
                [op release];
            }
        }
    }
    
    if (downloadMode == InAppPurchaseMode) {
        // rimpiazza il mio indice locale con quello server e sbattitene dei file
        [self replaceMyIndexWithLastUpdate];
        // sort injection
        [self sortSelector];
    }
	
	// bounce to external delegate
	if (remoteIndexDelegate)
        [remoteIndexDelegate remoteIndexDownloaded:documentIndex];
}

- (void) updatesAvailable:(TDMatchResults *)updates {
    
    if (downloadMode == CompleteSyncMode) {
        NSLog(@"[DownloadManager] downloadMode is CompleteSync: start automatic download.");
        [self performCompleteUpdate:updates];
    } else if (downloadMode == InAppPurchaseMode) {
        //        NSLog(@"[DownloadManager] downloadMode is InAppPurchase: start automatic download of icons and previews");
        //        downloadType = downloadIconAndPreview;
        //        [self performCompleteUpdate:updates];
    }
    
    if (remoteIndexDelegate)
        [remoteIndexDelegate updatesAvailable:updates];
}

#pragma mark -
#pragma mark TDDownloadDelegate standard implementation

- (void) didStartDownload:(TDDocument*)document {
	NSLog(@"Download started");
    
	// bounce to external delegate
    SEL selector = @selector(didStartDownload:);
	if (downloadDelegate && [(NSObject*)downloadDelegate respondsToSelector:selector])
        [(NSObject*)downloadDelegate performSelectorOnMainThread:selector withObject:document waitUntilDone:NO];
}

- (void) didFinishDownload:(TDDocument *)document {
    NSLog(@"Download finished");
    
	// bounce to external delegate
    SEL selector = @selector(didFinishDownload:);
	if (downloadDelegate && [(NSObject*)downloadDelegate respondsToSelector:selector])
        [(NSObject*)downloadDelegate performSelectorOnMainThread:selector withObject:document waitUntilDone:NO];
}

#pragma mark Progresses

- (void) fileDownloading:(TDDocument*)document progress:(float)progress {
    
    //    NSLog(@"%@ - %f",document.title,progress);
	
	// bounce to external delegate on main thread because probably UI is involved here
    SEL selector = @selector(fileDownloading:progress:);
	if (downloadDelegate && [(NSObject*)downloadDelegate respondsToSelector:selector])
        [downloadDelegate fileDownloading:document progress:progress];
    
    // analyze the document for bouncing out TDDownloadManagerDelegate
    //    float balancedProgress = 0.0f;
    //    if (document.filename && [self isDownloadingDocument:document])
    //        balancedProgress = progress / 4.0f;
    //    else
    //        balancedProgress = 0.25f;
    //    if (document.assetsname && [document isAssetsDownloaded])
    //        balancedProgress += 0.25f;
    //    else
    //        balancedProgress += progress / 4.0f;
    
    if (document.assetsname) {
        // valore compreso tra 0.0 e 0.25
        document.overallProgress = progress / 4.0f;
    } else {
        // l'asset non è presente, quindi
        // valore compreso tra 0.0 e 0.5
        document.overallProgress = progress / 2.0f;
    }
    
    // bounce to external delegate on main thread because probably UI is involved here
	if (downloadManagerDelegate && [(NSObject*) downloadManagerDelegate respondsToSelector:@selector(downloadOverallProgress:)]) {
        if ([NSThread isMainThread])
            [(id<TDDownloadManagerDelegate>)downloadManagerDelegate downloadOverallProgress:document];
        else
            dispatch_sync(dispatch_get_main_queue(), ^{
                [(id<TDDownloadManagerDelegate>)downloadManagerDelegate downloadOverallProgress:document];
            });
    }
}

- (void) assetDownloading:(TDDocument*)document progress:(float)progress {
    
    // bounce to external delegate on main thread because probably UI is involved here
    SEL selector = @selector(assetDownloading:progress:);
	if (downloadDelegate && [(NSObject*)downloadDelegate respondsToSelector:selector])
        [downloadDelegate assetDownloading:document progress:progress];
    
    // valore compreso tra 0.25 e 0.5
    document.overallProgress = 0.25f + progress / 4.0f;
    
    // bounce to external delegate on main thread because probably UI is involved here
	if (downloadManagerDelegate && [(NSObject*) downloadManagerDelegate respondsToSelector:@selector(downloadOverallProgress:)])
        [(NSObject*) downloadManagerDelegate performSelectorOnMainThread:@selector(downloadOverallProgress:) withObject:document waitUntilDone:NO];
}

- (void) iconDownloading:(TDDocument *)document progress:(float)progress {
    
    // bounce to external delegate on main thread because probably UI is involved here
    SEL selector = @selector(iconDownloading:progress:);
	if (downloadDelegate && [(NSObject*)downloadDelegate respondsToSelector:selector]) {
        if ([NSThread isMainThread])
            [downloadDelegate iconDownloading:document progress:progress];
        else
            dispatch_sync(dispatch_get_main_queue(), ^{
                [downloadDelegate iconDownloading:document progress:progress];
            });
    }
}

- (void) previewDownloading:(TDDocument *)document progress:(float)progress {
    
    // aggiornamento progress
    document.overallProgress = progress;
    
    // bounce to external delegate on main thread because probably UI is involved here
    SEL selector = @selector(previewDownloading:progress:);
	if (downloadDelegate && [(NSObject*)downloadDelegate respondsToSelector:selector]) {
        if ([NSThread isMainThread])
            [downloadDelegate previewDownloading:document progress:progress];
        else
            dispatch_sync(dispatch_get_main_queue(), ^{
                [downloadDelegate previewDownloading:document progress:progress];
            });
    }
}

- (void) didFinishFileDownload:(TDDocument*)document withCommand:(TDMatchResultCase)theCommand {
	if (TDMatchResultCaseError == theCommand) {
		NSLog(@"----> An error occurred while performing a DOWNLOAD or a DELETE operation.");
	} else {
		NSLog(@"----> Operation finished successfully.");
	}
    
	NSLog(@"REMOVED an operation in queue.");
	if (queue.operationCount == 0) {
		// do something
	}
    
    // analize the document for setting the download status and call TDDownloadManagerDelegate if available
    if ([document isEverythingDownloaded]) {
        // inject the change of downloadTable in DM
        [self setDownloadStatus:DownloadStatusDownloaded toDocument:document];
        // bounce to external delegate
        if (downloadManagerDelegate)
            [(NSObject*)downloadManagerDelegate performSelectorOnMainThread:@selector(didFinishDownload:) withObject:document waitUntilDone:NO];
    }
	
	// bounce to external delegate
	if (downloadDelegate) [downloadDelegate didFinishFileDownload:document withCommand:theCommand];
}

- (void) didFinishIconDownload:(TDDocument*)document {
    // bounce to external delegate
	if (downloadDelegate) [(NSObject*)downloadDelegate performSelectorOnMainThread:@selector(didFinishIconDownload:) withObject:document waitUntilDone:NO];
}

- (void) didFinishPreviewDownload:(TDDocument*)document withCommand:(TDMatchResultCase)theCommand {
    // bounce to external delegate
	if (downloadDelegate) [downloadDelegate didFinishPreviewDownload:document withCommand:theCommand];
}

#pragma mark Failure

- (void) downloadFailed:(TDDocument *)document withError:(NSError *)error {
    
    // inject the change of downloadTable in DM
    [self setDownloadStatus:DownloadStatusUnavailable toDocument:document];
	
	// bounce to external delegate
	if (downloadDelegate) [downloadDelegate downloadFailed:document withError:error];
}

- (void) downloadIconFailed:(TDDocument *)document withError:(NSError *)error {
    
    NSLog(@"[TDDownload] downloadIconFailed for document: %@",document);
    
    // bounce to external delegate
	if (downloadDelegate && [(NSObject*)downloadDelegate respondsToSelector:@selector(downloadIconFailed:withError:)])
        [downloadDelegate downloadIconFailed:document withError:error];
}

- (void) downloadPreviewFailed:(TDDocument *)document withError:(NSError *)error {
    
    // bounce to external delegate
	if (downloadDelegate && [(NSObject*)downloadDelegate respondsToSelector:@selector(downloadPreviewFailed:withError:)])
        [downloadDelegate downloadPreviewFailed:document withError:error];
}

- (void) downloadsExecuting:(NSUInteger)numOfDownloads {
	
	//IGNORING numOfDownloads not used for now
	NSLog(@"downloadsExecuting: The number of downloads in queue is: %i",queue.operationCount);
	
	// SORTING INJECTION
	if (numOfDownloads == 0) {
		[self sortSelector];
		[self serializeMyIndex];
	}
	
	// bounce to external delegate
    SEL selector = @selector(downloadsExecuting:);
	if (downloadDelegate && [(NSObject*)downloadDelegate respondsToSelector:selector])
        [(NSObject*)downloadDelegate performSelectorOnMainThread:selector withObject:[NSNumber numberWithUnsignedInt:numOfDownloads] waitUntilDone:NO];
}

@end
