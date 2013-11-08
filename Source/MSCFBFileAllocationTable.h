//
//  MSCFBFileAllocationTable.h
//
//  Created by Hervey Wilson on 11/7/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#pragma once

@class MSCFBFile;

@interface MSCFBFileAllocationTable : NSObject

- (id)init:(MSCFBFile __weak *)header error:(NSError * __autoreleasing *)error;

- (u_int32_t)nextSectorInChain:(u_int32_t)index;
- (u_int32_t)sectorsInChain:(u_int32_t)startIndex;


@end
