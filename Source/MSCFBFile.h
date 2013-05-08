//
//  MSCompoundFile.h
//
//  Created by Hervey Wilson on 3/6/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@class MSCFBObject;

@interface MSCFBFile : NSObject

- (id)initWithData:(NSData *)data error:(NSError * __autoreleasing *)error;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError * __autoreleasing *)error;

- (MSCFBObject *)objectForKey:(NSString *)key;

@end
