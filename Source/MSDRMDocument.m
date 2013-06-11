//
//  MSDRMDocument.m
//
//  Created by Hervey Wilson on 4/23/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#include <zlib.h>

#import "MSCFBObject.h"
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

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)outError
{
    if ( outError )
        *outError = nil;
    
    self = [super init];
    
    if ( self )
    {
        _file = [[MSDRMFile alloc] initWithData:data error:outError];
        
        [self validate];
    }

    return self;
}


- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    self = [self initWithData:[fileHandle readDataToEndOfFile] error:error];
    
    return self;
}


/*
// The default implementation of this method reads all the file data and calls readFromData:ofType:error
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return [super readFromFileWrapper:fileWrapper ofType:typeName error:outError];
}

// The default implementation of this method creates a file wrapper and calls readFromFileWrapper:ofType:error
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return [super readFromURL:url ofType:typeName error:outError];
}
*/

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

- (NSString *)pathForTemporaryFileWithPrefix:(NSString *)prefix
{
    NSString   *result;
    CFUUIDRef   uuid;
    CFStringRef uuidString;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidString = CFUUIDCreateString(NULL, uuid);
    assert(uuidString != NULL);
    
    result = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@", prefix, uuidString]];
    assert(result != nil);
    
    CFRelease(uuidString);
    CFRelease(uuid);
    
    return result;
}


@end
