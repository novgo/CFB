//
//  MSDRMDocument.h
//  MSCFB-OSX
//
//  Created by Hervey Wilson on 4/23/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@class MSDRMFile;

@interface MSDRMDocument : NSObject

@property (readonly, nonatomic) NSData    *license;
@property (readonly, nonatomic) NSData    *content;
@property (readonly, nonatomic) u_int32_t  contentLength;

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)outError;

- (MSDRMFile *)compoundFile;

@end
