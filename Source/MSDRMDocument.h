//
//  MSDRMDocument.h
//
//  Created by Hervey Wilson on 4/23/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@class MSDRMFile;

@interface MSDRMDocument : NSObject

@property (readonly, nonatomic) NSData    *license;
@property (readonly, nonatomic) NSData    *protectedContent;
@property (readonly, nonatomic) u_int32_t  protectedContentLength;

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)outError;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error;

- (MSDRMFile *)compoundFile;

@end
