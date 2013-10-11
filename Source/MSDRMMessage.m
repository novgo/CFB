//
//  MSDRMMessage.m
//
//  Created by Hervey Wilson on 3/18/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//
#include <zlib.h>

#import "MSCFBError.h"

#import "MSCFBObject.h"
#import "MSCFBStorage.h"
#import "MSCFBStream.h"
#import "MSCFBFile.h"
#import "MSCFBSource.h"

#import "MSDRMFile.h"

#import "MSDRMMessage.h"

typedef struct _BlockHeader
{
    u_int32_t ulCheck;
    u_int32_t sizeAfterInflation;
    u_int32_t sizeBeforeInflation;
} BLOCKHEADER;

#define ZLIB_BUFFER_SIZE      (4 * 1024)
#define ZLIB_DRM_HEADER_MAGIC (0x0FA0)

static const unsigned char compressedDrmMessageHeader[] = { '\x76', '\xE8', '\x04', '\x60', '\xC4', '\x11', '\xE3', '\x86' };

@implementation MSDRMMessage
{
    MSDRMFile *_file;
}

#pragma mark - Initialization and Termination

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;

    MSCFBDataSource *source = [[MSCFBDataSource alloc] initWithData:data];
    
    return [self initWithSource:source error:error];
}

- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    if ( !ASSERT( error, fileHandle != 0, @"Invalid file handle" ) )
        return nil;

    MSCFBFileSource *source = [[MSCFBFileSource alloc] initWithFileHandle:fileHandle];
    
    return [self initWithSource:source error:error];
}

- (id)initWithSource:(id<MSCFBSource>)source error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    self = [super init];
    
    if ( self )
    {
        // Try to deflate the data
        NSData *deflatedData = [self decompress:source error:error];
        
        if ( !deflatedData )
        {
            self = nil;
        }
        else
        {
            // Load the deflated data
            _file = [[MSDRMFile alloc] initWithData:deflatedData error:error];
            
            if ( _file )
            {
                _license          = _file.license;
                _protectedContent = _file.protectedContent;
            }
            else
            {
                self = nil;
            }
        }
    }
    
    return self;
}

#pragma mark - Public Methods

- (MSDRMFile *)compoundFile
{
    return _file;
}

#pragma mark - Internal Methods

- (NSData *)decompress:(id<MSCFBSource>)compressedData error:(NSError * __autoreleasing *)error
{
    if ( error ) *error = nil;
    
    unsigned char  szHeader[sizeof(compressedDrmMessageHeader)] = {0};
    NSRange        range                                        = NSMakeRange(0,sizeof(compressedDrmMessageHeader));
    
    [compressedData getBytes:szHeader range:range];
    
    if ( !ASSERT( error, memcmp( szHeader, compressedDrmMessageHeader, sizeof( compressedDrmMessageHeader) ) == 0, @"Invalid message magic value" ) )
        return nil;
    
    z_stream zcpr;
    
    BLOCKHEADER    blockHeader   = {0};
    Byte          *deflatedBlock = malloc( 4096 << 1 ); // Blocks are generally ~4k
    Byte          *inflatedBlock = malloc( 4096 << 1 ); // Blocks are generally ~4k
    NSMutableData *deflatedData  = [[NSMutableData alloc] init];
    
    int ret=Z_OK;
    
    memset(&zcpr,0,sizeof(z_stream));
    
    inflateInit(&zcpr);
    
    range.location += range.length;
    
    while ( deflatedData && ret == Z_OK && range.location < compressedData.length )
    {
        // Read the block header
        range.length = sizeof( BLOCKHEADER );
        [compressedData getBytes:&blockHeader range:range];
        
        if ( ASSERT( error, blockHeader.ulCheck == ZLIB_DRM_HEADER_MAGIC, @"Incorrect block magic value" ) )
        {
            if ( ASSERT( error, ( blockHeader.sizeBeforeInflation <= ( 4096 << 1 ) ) || ( blockHeader.sizeAfterInflation <= ( 4096 << 1 ) ), @"Size after inflation exceeds allocated space" ) )
            {
                // Read the compressed data
                range.location += range.length; // Skip over header
                range.length    = blockHeader.sizeBeforeInflation;

                if ( ASSERT( error, range.location + range.length <= compressedData.length, @"Compressed data corrupt" ) )
                {
                    [compressedData getBytes:deflatedBlock range:range];
                    
                    // Deflate the data
                    zcpr.next_in   = deflatedBlock;
                    zcpr.avail_in  = blockHeader.sizeBeforeInflation;
                    
                    zcpr.next_out  = inflatedBlock;
                    zcpr.avail_out = blockHeader.sizeAfterInflation;
                    
                    ret = inflate( &zcpr, Z_SYNC_FLUSH );
                    
                    if ( ret == Z_OK )
                    {
                        [deflatedData appendBytes:inflatedBlock length:blockHeader.sizeAfterInflation];
                    }
                    
                    // Skip to next block header
                    range.location += range.length;
                }
                else
                {
                    // Drop the deflated data if there is an error.
                    deflatedData = nil;
                }
            }
            else
            {
                // Drop the deflated data if there is an error.
                deflatedData = nil;
            }
        }
        else
        {
            // Drop the deflated data if there is an error.
            deflatedData = nil;
        }
    }

    free( deflatedBlock );
    free( inflatedBlock );
    
    return deflatedData;
}

@end
