//
//  MSDRMFile.h
//
//  Created by Hervey Wilson on 4/23/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@interface MSDRMFile : MSCFBFile

@property (readonly, nonatomic) NSData   *license;
@property (readonly, nonatomic) NSData   *protectedContent;
@property (readonly, nonatomic) u_int64_t protectedContentLength;

- (id)initWithData:(NSData *)data error:(NSError * __autoreleasing *)error;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError * __autoreleasing *)error;

@end
