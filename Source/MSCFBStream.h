//
//  MSCFBStream.h
//
//  Created by Hervey Wilson on 3/12/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@class MSCFBDirectoryEntry;
@class MSCFBObject;

@interface MSCFBStream : MSCFBObject

@property (readonly, nonatomic) u_int64_t length;

- (id)init:(MSCFBDirectoryEntry *)entry container:(MSCFBFile *)container;

@end
