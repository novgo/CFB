//
//  MSCFBDirectoryEntry.h
//
//  Created by Hervey Wilson on 3/11/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBTypes.h"

@interface MSCFBDirectoryEntry : NSObject

@property (readwrite, nonatomic) NSString *name;
@property (readwrite, nonatomic) u_int32_t left;
@property (readwrite, nonatomic) u_int32_t right;
@property (readwrite, nonatomic) u_int32_t child;

@property (readwrite, nonatomic) Byte      objectType;

@property (readwrite, nonatomic) u_int64_t streamStart;
@property (readwrite, nonatomic) u_int64_t streamLength;

- (id)init;
- (id)init:(MSCFB_DIRECTORY_ENTRY *)directoryEntry;

- (void)getDirectoryEntry:(MSCFB_DIRECTORY_ENTRY *)directoryEntry;

@end
