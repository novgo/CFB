//
//  MSDRMMessage.h
//
//  Created by Hervey Wilson on 3/18/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@class MSDRMFile;

@interface MSDRMMessage : NSObject

@property (readonly, nonatomic) NSData *license;
@property (readonly, nonatomic) NSData *protectedContent;

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)outError;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error;

- (MSDRMFile *)compoundFile;

@end
