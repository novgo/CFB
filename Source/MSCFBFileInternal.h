//
//  MSCompoundFileInternal.h
//
//  Created by Hervey Wilson on 3/25/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#pragma once

@interface MSCFBFile ( Internal )

@property (readonly, nonatomic) u_int32_t miniStreamCutoffSize;


- (id)initWithData:(NSData *)data error:(NSError * __autoreleasing *)error;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError * __autoreleasing *)error;

- (id)initForWritingWithFileHandle:(NSFileHandle *)fileHandle error:(NSError * __autoreleasing *)error;


- (NSData *)readStream:(u_int32_t)index range:(NSRange)range;
- (NSData *)readMiniStream:(u_int32_t)index range:(NSRange)range;

@end