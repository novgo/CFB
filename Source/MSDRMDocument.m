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
}

#pragma mark - Public Properties

#pragma mark - Public Methods

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    self = [super initWithData:data error:error];
    
    if ( self )
    {
    }

    return self;
}

- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    self = [super initWithFileHandle:fileHandle error:error];
    
    if ( self )
    {
    }
    
    return self;
}

@end
