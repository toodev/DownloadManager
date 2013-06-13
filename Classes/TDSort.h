//
//  TDSort.h
//  DownloadManager
//
//  Created by Daniele Poggi on 6/18/10.
//  Copyright 2010 toodev. All rights reserved.
//

typedef enum {
	TDSortNone,
	TDSortByTitleAscending,
	TDSortByTitleDescending,
	TDSortByDocIdAscending,
	TDSortByDocIdDescending,
    TDSortByDateAscending,
    TDSortByDateDescending,
    TDSortByGroupAscending,
    TDSortByGroupDescending,
} TDSort;

@protocol TDSort


@end
