//
//  TDDownloadUnzipOperation.m
//  DownloadManager
//
//  Created by Daniele Poggi on 6/23/11.
//  Copyright 2011 toodev. All rights reserved.
//

#import "TDDownloadUnzipOperation.h"
#import "ZipArchive.h"

@implementation TDDownloadUnzipOperation

// final steps is overridden, called before didFinishDownload: delegate
// unzip the downloaded file in the same folder as the zip file
- (void) finalSteps {

    // check localPath exists
    if (!localPath) {
        TDLog(@"[TDDownloadUnzipOperation] ILLEGAL ARGUMENT: localPath is nil. Skipping...");
        return;
    }
    
    // check if localPath is a zip file
    if (![[localPath pathExtension] isEqualToString:@"zip"]) {
        TDLog(@"[TDDownloadUnzipOperation] cannot continue unzipping: %@ is not an archive.",localPath);
        return;
    }
    
    // creating local directory for unzipping
    NSString *localDir = [localPath stringByDeletingLastPathComponent];
    
    // check if localDir is directory
    BOOL isDir = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:localDir isDirectory:&isDir] && isDir) {
        TDLog(@"[TDDownloadUnzipOperation] cannot continue unzipping: cannot create local directory for storing files in archive.");
        return;
    }
    
    // unzip
    ZipArchive *zipArchive = [[ZipArchive alloc] init];
    [zipArchive UnzipOpenFile:localPath];
    [zipArchive UnzipFileTo:localDir overWrite:YES];
    [zipArchive UnzipCloseFile];
    [zipArchive release];
    
    NSLog(@"[TDDownloadUnzipOperation] UNZIPPED archive at path: %@",localDir);
    
    // delete zip file
    NSError *error;
    if (![[NSFileManager defaultManager] removeItemAtPath:localPath error:&error]) {
        NSLog(@"[TDDownloadUnzipOperation] cannot remove zip archive at path: %@",localPath);
        
        // leave the archive there...
        return;
    }
    
    // if the archive has been removed, create a fake 0 byte archive ;))))
    if (![[NSFileManager defaultManager] createFileAtPath:localPath contents:[NSData data] attributes:nil]) {
        NSLog(@"[TDDownloadUnzipOperation] cannot create zip archive replacement at path: %@",localPath);
    }
    
    NSLog(@"[TDDownloadUnzipOperation] CREATED archive replacement at path: %@",localDir);
}

@end
