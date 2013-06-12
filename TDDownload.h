//
//  TDDownload.h
//  DownloadManager
//
//  Created by Daniele Poggi on 5/24/10.
//  Copyright 2010 toodev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDMatchResults.h"
#import "TDMatchResultCase.h"
#import "TDSort.h"
#import "TDDocument.h"
#import "TDConnectionDelegate.h"
#import "TDRemoteIndexDelegate.h"
#import "TDDownloadDelegate.h"
#import "TDDownloadManagerDelegate.h"
#import "TDConnectionOperation.h"
#import "NSArrayAdditions.h"

#define kPREF_URL @"URL"
#define kPREF_RES @"resource"
#define kPREF_USERNAME @"username"
#define kPREF_PASSWORD @"password"
#define kUPDATE_FILE_NAME_PLIST @"update.plist"
#define kUPDATE_FILE_NAME_XML   @"update.xml"

#define kCONN_UNAVAILABLE 0
#define kCONN_AVAILABLE   1

#define kPDFFolderName     @"pdf"
#define kIconFolderName    @"thumbnail"
#define kPreviewFolderName @"preview"
#define kAssetsFolderName  @"assets"

///////////////////////////////////////////////
// DOWNLOAD PARAMETERS
///////////////////////////////////////////////
#define kDownloadTimeoutInterval 1800

typedef enum {
    Plist,
    XML,
    Binary
} UpdateFileType;

typedef enum {
    CompleteSyncMode, // auto sync of files
    InAppPurchaseMode // on demand download
} DownloadMode;

typedef enum {
    DownloadStatusAvailable,
    DownloadStatusDownloading,
    DownloadStatusDownloaded,
    DownloadStatusUnavailable
} DownloadStatus;

typedef enum {
    DownloadTypeNothing,
    DownloadTypeIcon,
    DownloadTypePreview,
    DownloadTypeFile,
    DownloadTypeAsset
} DownloadType;

@interface TDDownload : NSObject <TDConnectionDelegate, TDRemoteIndexDelegate, TDDownloadDelegate> {
    
    //! the kind of update file to be used for this client-server connection
    UpdateFileType updateFileType;
    
    //! the kind of update file to be stored locally
    UpdateFileType localUpdateFileType;
    
    //! the kind of download the manager must use to retrieve data
    DownloadMode downloadMode;

    //! number of downloads
//	NSUInteger numDownloads;
    
    //! connection status
	NSInteger connectionStatus;
    
    //! a table that stores the document index and the current download status
    NSMutableDictionary *downloadTable;
    
    // FOLDERS
    
    //! the local pdf storage
    NSString *pdfFolder;
    
    //! the local thumbnail storage
    NSString *iconFolder;
    
    //! the local preview storage
    NSString *previewFolder;
    
    //! the local asset storage
    NSString *assetFolder;
	
	@private	
	//! connection preferences. The form of the dictionary is specified on the initWithProperties: constructor.
	NSDictionary *_preferences;
	//! an instance of file manager to manage files discovery and directories
	NSFileManager *fileManager;
	//! the local path that points to the current document index
	NSString *descriptionPath;
	
	//! the description array containing all the actual resources
	NSMutableArray *documentIndex;
	//! the description array containing the updated description if available.
	NSMutableArray *updatedDocumentIndex;
	//! the connection url, found valid and used to retrieve the update and the resources
	NSString *remoteConnectionPath;
	//! the remote connection URL used to retrieve the update
	NSURL *remoteConnectionURL;
	//! the credentials needed to connect to a web server
	NSURLCredential *credential;
    
	//! the operation queue
	NSOperationQueue *queue;
	// the connection operation, is a constraint for the download operations
	TDConnectionOperation *connectionOperation;
	// the last sorting rule requested by a performCompleteUpdate
	TDSort currentSort;
        
	//! the connection delegate
	id <TDConnectionDelegate> connectionDelegate;
	//! the remote index delegate
	id <TDRemoteIndexDelegate> remoteIndexDelegate;
	//! the TDDownloadDelegate used for notify the state of the download
	id <TDDownloadDelegate> downloadDelegate;	
    //! a simplified download manager delegate for managing complex documents
    id <TDDownloadManagerDelegate> downloadManagerDelegate;
}

@property (nonatomic, assign) UpdateFileType updateFileType;
@property (nonatomic, assign) UpdateFileType localUpdateFileType;
@property (nonatomic, assign) DownloadMode downloadMode;

@property (nonatomic, assign) NSInteger connectionStatus;
@property (nonatomic, assign) NSFileManager *fileManager;
@property (nonatomic, assign) TDSort currentSort;

@property (nonatomic, retain) NSString *pdfFolder;
@property (nonatomic, retain) NSString *iconFolder;
@property (nonatomic, retain) NSString *previewFolder;
@property (nonatomic, retain) NSString *assetFolder;

@property (nonatomic, retain) NSDictionary			*preferences;
@property (nonatomic, retain) NSString              *descriptionPath;
@property (nonatomic, retain) NSMutableArray		*documentIndex;
@property (nonatomic, retain) NSMutableArray		*updatedDocumentIndex;
@property (nonatomic, copy) NSString				*remoteConnectionPath;
@property (nonatomic, retain) NSURL					*remoteConnectionURL;
@property (nonatomic, retain) NSURLCredential		*credential;
@property (nonatomic, retain) NSOperationQueue		*queue;
@property (nonatomic, retain) TDConnectionOperation *connectionOperation;

@property (nonatomic, readonly) NSMutableDictionary *downloadTable;

@property(nonatomic, assign) id <TDConnectionDelegate> connectionDelegate;
@property(nonatomic, assign) id <TDRemoteIndexDelegate> remoteIndexDelegate;
@property(nonatomic, assign) id <TDDownloadDelegate> downloadDelegate;
@property(nonatomic, assign) id <TDDownloadManagerDelegate> downloadManagerDelegate;

#pragma mark -
#pragma mark Initialization

/*!
    @method     initWithPreferences:
    @abstract   a programmatic oriented Cosntructor
    @discussion use this constructor if you don't need the delegate and you need to programmatically build the connection preferences.
    @param      aPreferences an NSDictionary with this form:
				- keys must be of two types:
				1) URL0, URL1, URL2 ....
					multiple connection urls are supported, the first working will be used
					An Example of URL: http://your.company.com/resources
				2) resource0, resource1, resource2 ...
					multiple resource names are supported, the first found will be used
					An Example of resource: update.plist	(Explanation of how to write a Resource plist here)
				
				An Example:
				NSArray *keys = [NSArray arrayWithObjects:@"URL0",@"resource0",@"URL1",@"resource1",nil];
				NSArray *values = [NSArray arrayWithObjects:@"http://subversion.bounceme.net/wephone",@"update.plist",@"http://subversion.bounceme.net/dm",@"waaa.plist",nil];
				NSDictionary *prefs = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    @result     a new instance of TDDownload
*/
- (id) initWithPreferences:(NSDictionary*)aPreferences;

/*!
    @method     sharedInstance
    @abstract   the shared instance getter
    @discussion allows the access of a download manager through a singleton instance.
                automatically loads preferences from a plist "Properties" that MUST be present in bundle.
                returns nil if Preferences.plist is not found.
 */
//+ (id) sharedInstance;

/*!
 @method     checkAndCreateStorages
 @abstract   initialize variables for storages
 @discussion there are multiple storages available for keeping different kind of data.
             with this function you check and create them if not found.
 */
- (void) checkAndCreateStorages;

#pragma mark -
#pragma mark Connection

- (void) preConnectionStuff;

/*!
    @method      chooseUpdateURL
    @abstract    Accessory method for test the connection preferences and choose the first responding.
    @discussion  This convenience method is NOT called automatically since requires internet connection.
				 If a call to loadCompleteIndex or loadUpdates is done, this method is called first.
*/
- (void) chooseUpdateURL;

#pragma mark -
#pragma mark MyIndex

/*!
    @method      loadMyIndex
    @abstract    Returns an NSArray of TDDocument describing the actual state of documents available under the scope of DownloaderManager.
    @discussion  This is the accessory method for de-serializing the actual documents downloaded and described locally.
    @result      the current retained NSArray of TDDocuments that are completely downloaded and described.
*/
- (NSMutableArray*) loadMyIndex;

/*!
    @method      checkMyIndex
    @abstract    Parses the current local index of documents.
    @discussion  Optional method for verify the robustness of the local index. is called automatically and is atomic.
				 TODO: return a list of parsing errors.
    @result      YES if the local index is robust, NO if has problems.
*/
- (BOOL) checkMyIndex;

- (void) serializeMyIndex;

/*!
    @method      replaceMyIndexWithLastUpdate
    @abstract    replace the local document index with the new index from the update
    @discussion  
    @result      the old document index
*/
- (void) replaceMyIndexWithLastUpdate;

/*!
    @method      replaceMyIndexWithUpdate:
    @abstract    replace the local document index with the new index passed as argument
    @discussion 
    @param       updatedIndex the new remote index of documents being downloaded
*/
- (void) replaceMyIndexWithUpdate:(NSArray*)updatedIndex;

//- (void) insertMyIndex:(TDDocumentRemote*) updatedIndex;

/*!
    @method     replaceMyIndex:WithIndex:
    @abstract   replace one of the local document description with one of its updates
    @discussion 
    @param      myIndex an old TDDocument
    @param      updatedIndex a new version of TDDocument
*/
//- (void) replaceMyIndex:(TDDocument*)myIndex WithIndex:(TDDocumentRemote*)updatedIndex;

#pragma mark -
#pragma mark CompleteIndex

- (void) loadCompleteIndex;

- (void) loadCompleteIndexShowUpdates:(BOOL)updatesAvailable;


/*!
    @method     isLocallyPresent:
    @abstract   checks if a remote descriptor has been managed locally
    @discussion browses the local resources searching for a local descriptor that matches its document ID with the remote one.
				if found, return the local retained descriptor
    @param      remoteDoc the remote document taken from the server descriptors
    @result     the local retained descriptor, or nil if nothing has been found.
*/
- (TDDocument*) isLocallyPresent:(TDDocument*)remoteDoc inArray:(NSArray*)anArray;

#pragma mark -
#pragma mark Matches

/*!
    @method      compareLocalWithLastUpdate
    @abstract    compare the local index with the updated one from the server and returns all the matching updates
    @discussion  this method returns all the UPDATED and NEW documents found by matching all the remote documents with the local ones.
    @result      an autorelease instance of TDMatchResults containing
*/
- (TDMatchResults*) compareLocalWithRemote;

/*!
    @method     processForUpdate:
    @abstract   modifies a TDDocumentRemote updating newDoc and updateDoc variables
    @discussion the method checks the local documents and identify if the remote document represents a new or update resource
    @param      remoteDocument the remote document 
    @result     the result of the processing, can be nothing, a new command or an update command
*/
- (TDMatchResultCase) processForUpdate:(TDDocument*)remoteDocument inLocalIndex:(NSArray*)anIndex;

- (TDMatchResultCase) processForDelete:(TDDocument *)localDocument inRemoteIndex:(NSArray*)anIndex;
- (void) deleteFiles:(TDDocument*)anIndex ;

#pragma mark -
#pragma mark Operations and queues

/*!
 @method      performUpdate:
 @abstract    update a local document with a remote one.
 @discussion  The atomic action first checks the document to be updated, then corrects its description when finished.
 @param       updatedDocument the TD
 @result      YES if the action finished without problems, NO otherwise.
 */
- (BOOL) performUpdate:(TDDocument*)updatedDocument;

- (BOOL) performUpdate:(TDDocument*)updatedDocument withMatchResult:(TDMatchResultCase)matchCase;

/*!
 @method      performCompleteUpdate:
 @abstract    updates all the local documents marked to be UPDATED or NEW, or with unfinished DOWNLOAD
 @discussion  Iterates through the match results and updates all the files accordingly.
 @param       updates the result a compare local with remote function. Cannot be created by hand.
 @result      YES if the action finished without problems, NO otherwise.
 */
- (BOOL) performCompleteUpdate:(TDMatchResults*)updates;

- (BOOL) performCompleteUpdate:(TDMatchResults*)updates WithSort:(TDSort)aSort;

#pragma mark -
#pragma mark Download

- (BOOL) isDownloadingDocument:(TDDocument*)document;

- (void) setDownloadStatus:(DownloadStatus)downloadStatus toDocument:(TDDocument*)document;

#pragma mark -
#pragma mark CRUD operations on TDDocument

- (void) deleteIndex:(TDDocument *)anIndex;

- (void) archiveIndex:(TDDocument*)anIndex;

#pragma mark -
#pragma mark Utilities

- (NSMutableArray*) loadLibraryIndexFromIndex:(NSMutableArray*)myIndex;

@end
