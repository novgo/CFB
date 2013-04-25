//
//  MSDRMFile.h
//  MSCFB-OSX
//
//  Created by Hervey Wilson on 4/23/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import <MSCFB/MSCFB.h>

@interface MSDRMFile : MSCFBFile

@property (readonly, nonatomic) NSData   *license;
@property (readonly, nonatomic) NSData   *content;
@property (readonly, nonatomic) u_int64_t contentLength;

- (id)initWithData:(NSData *)data error:(NSError * __autoreleasing *)error;

@end
