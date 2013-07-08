//
//  MSDRMDocument.m
//
//  Created by Hervey Wilson on 4/23/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#include <zlib.h>

#import "MSCFBObject.h"
#import "MSCFBSource.h"
#import "MSCFBStorage.h"
#import "MSCFBStream.h"
#import "MSCFBFile.h"
#import "MSDRMFile.h"

#import "MSDRMDocument.h"

@implementation MSDRMDocument
{
    MSDRMFile *_file;
}

#pragma mark - Public Properties

#pragma mark - Public Methods

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    self = [super init];
    
    if ( self )
    {
        _file = [[MSDRMFile alloc] initWithData:data error:error];
        
        [self validate];
    }

    return self;
}


- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    self = [super init];
    
    if ( self )
    {
        _file = [[MSDRMFile alloc] initWithFileHandle:fileHandle error:error];
        
        [self validate];
    }
    
    return self;
}

- (MSDRMFile *)compoundFile
{
    return _file;
}

#pragma mark - Private Methods

- (void)validate
{
    _license                = _file.license;
    _protectedContent       = _file.protectedContent;
    _protectedContentLength = _file.protectedContentLength;
}

@end
