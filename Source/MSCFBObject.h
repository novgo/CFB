//
//  MSCFBObject.h
//
//  Created by Hervey Wilson on 3/22/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#pragma once

@class MSCFBDirectoryEntry;
@class MSCFBFile;

@interface MSCFBObject : NSObject

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) Byte      objectType;

- (id)init __attribute__( ( unavailable("init not available") ) );

- (NSData *)read:(NSRange)range;
- (NSData *)readAll;

@end
