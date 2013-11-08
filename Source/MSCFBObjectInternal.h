//
//  MSCFBObjectInternal.h
//
//  Created by Hervey Wilson on 3/25/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#pragma once

@class MSCFBDirectoryEntry;

@interface MSCFBObject ( Internal )

@property (readonly, nonatomic) MSCFBDirectoryEntry *directoryEntry;

- (id)init:(MSCFBDirectoryEntry *)entry container:(MSCFBFile *)container;

@end