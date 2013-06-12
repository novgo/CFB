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

#pragma mark - Public Properties

#pragma mark - Public Methods

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    NSError *internalError = nil;
    
    self = [super init];
    
    if ( self )
    {
        NSData *deflatedData = [self decompress:data error:&internalError];
        
        if ( internalError )
        {
            self = nil;
        }
        else
        {
            _file = [[MSDRMFile alloc] initWithData:deflatedData error:&internalError];

            if ( !internalError )
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

- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    if ( !ASSERT( error, fileHandle != 0, @"Invalid file handle" ) )
        return nil;
    
    [fileHandle seekToFileOffset:0];
    self = [self initWithData:[fileHandle readDataToEndOfFile] error:error];
    
    return self;
}

- (MSDRMFile *)compoundFile
{
    return _file;
}

- (NSData *)decompress:(NSData *)compressedData error:(NSError * __autoreleasing *)error
{
    if ( error ) *error = nil;
    
    unsigned char szHeader[sizeof(compressedDrmMessageHeader)] = {0};
    
    [compressedData getBytes:szHeader length:sizeof( compressedDrmMessageHeader)];
    
    if ( !ASSERT( error, memcmp( szHeader, compressedDrmMessageHeader, sizeof( compressedDrmMessageHeader) ) == 0, @"Invalid message magic value" ) )
        return nil;
    
    z_stream zcpr;
    
    BLOCKHEADER    blockHeader   = {0};
    Byte          *deflatedBlock = malloc( 4096 << 1 ); // Blocks are generally ~4k
    Byte          *inflatedBlock = malloc( 4096 << 1 ); // Blocks are generally ~4k
    NSRange        range         = NSMakeRange(0,0);
    NSMutableData *deflatedData  = [[NSMutableData alloc] init];
    
    int ret=Z_OK;
    
    memset(&zcpr,0,sizeof(z_stream));
    
    inflateInit(&zcpr);
    
    range.location = sizeof( szHeader );
    
    while ( *error == nil && ret == Z_OK && range.location < compressedData.length )
    {
        // Read the block header
        range.length = sizeof( BLOCKHEADER );
        [compressedData getBytes:&blockHeader range:range];
        
        if ( ASSERT( error, blockHeader.ulCheck == ZLIB_DRM_HEADER_MAGIC, @"Incorrect block magic value" ) )
        {
            if ( ASSERT( error, ( blockHeader.sizeBeforeInflation <= ( 4096 << 1 ) ) || ( blockHeader.sizeAfterInflation <= ( 4096 << 1 ) ), @"Size after inflation exceeds allocated space" ) )
            {
                // Read the compressed data
                range.location += sizeof( BLOCKHEADER ); // Skip over header
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
                    range.location += blockHeader.sizeBeforeInflation;
                }
            }
        }
    }
    
    free( deflatedBlock );
    free( inflatedBlock );
    
    if ( *error )
        return nil;
    else
        return deflatedData;
}

@end
