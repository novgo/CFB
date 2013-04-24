//
//  MSCFBDirectoryEntry.h
//
//  Created by Hervey Wilson on 3/11/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBTypes.h"

@class MSCFBFile;

@interface MSCFBDirectoryEntry : NSObject

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) u_int32_t left;
@property (readonly, nonatomic) u_int32_t right;
@property (readonly, nonatomic) u_int32_t child;

@property (readonly, nonatomic) Byte      objectType;

@property (readonly, nonatomic) u_int64_t streamLength;

- (id)init:(MSCFB_DIRECTORY_ENTRY *)directoryEntry container:(MSCFBFile *)container;

- (NSData *)read:(NSRange)range;
- (NSData *)readAll;

@end
