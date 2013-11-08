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
#import "MSDRMDocument.h"
#import "MSDRMMessage.h"

typedef struct _BlockHeader
{
    u_int32_t ulCheck;
    u_int32_t sizeDecompressed;
    u_int32_t sizeCompressed;
} BLOCKHEADER;

#define ZLIB_BUFFER_SIZE      (4 * 1024)
#define ZLIB_DRM_HEADER_MAGIC (0x0FA0)

static const unsigned char compressedDrmMessageHeader[] = { '\x76', '\xE8', '\x04', '\x60', '\xC4', '\x11', '\xE3', '\x86' };

@implementation MSDRMMessage
{
}

#pragma mark - Public Properties


#pragma mark - Public Methods

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;

    MSCFBDataSource *source = [[MSCFBDataSource alloc] initWithData:data];
    
    NSError *internalError = nil;
    NSData  *deflatedData  = [self decompress:source error:&internalError];
    
    if ( internalError )
    {
        if ( error ) *error = internalError;
        self = nil;
    }
    else
    {
        self = [super initWithData:deflatedData error:&internalError];
        
        if ( internalError )
        {
            if ( error ) *error = internalError;
            self = nil;
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

    MSCFBFileSource *source = [[MSCFBFileSource alloc] initWithFileHandle:fileHandle];
    
    NSError *internalError = nil;
    NSData  *deflatedData  = [self decompress:source error:&internalError];
    
    if ( internalError )
    {
        if ( error ) *error = internalError;
        self = nil;
    }
    else
    {
        self = [super initWithData:deflatedData error:&internalError];
        
        if ( internalError )
        {
            if ( error ) *error = internalError;
            self = nil;
        }
    }
    
    return self;
}

#pragma mark - Private Methods

- (NSData *)decompress:(id<MSCFBSource>)compressedData error:(NSError * __autoreleasing *)error
{
    if ( error ) *error = nil;
    
    unsigned char  szHeader[sizeof(compressedDrmMessageHeader)] = {0};
    NSRange        range                                        = NSMakeRange(0,sizeof(compressedDrmMessageHeader));
    
    [compressedData readBytes:szHeader range:range];
    
    if ( !ASSERT( error, memcmp( szHeader, compressedDrmMessageHeader, sizeof( compressedDrmMessageHeader) ) == 0, @"Invalid message magic value" ) )
        return nil;
    
    z_stream zcpr;
    
    BLOCKHEADER    blockHeader       = {0};
    Byte          *compressedBlock   = malloc( 4096 << 1 ); // Blocks are generally ~4k
    Byte          *decompressedBlock = malloc( 4096 << 1 ); // Blocks are generally ~4k
    NSMutableData *deflatedData      = [[NSMutableData alloc] init];
    
    int ret=Z_OK;
    
    memset(&zcpr,0,sizeof(z_stream));
    
    inflateInit(&zcpr);
    
    range.location += range.length;
    
    while ( *error == nil && ret == Z_OK && range.location < compressedData.length )
    {
        // Read the block header
        range.length = sizeof( BLOCKHEADER );
        [compressedData readBytes:&blockHeader range:range];
        
        if ( ASSERT( error, blockHeader.ulCheck == ZLIB_DRM_HEADER_MAGIC, @"Incorrect block magic value" ) )
        {
            if ( ASSERT( error, ( blockHeader.sizeCompressed <= ( 4096 << 1 ) ) || ( blockHeader.sizeDecompressed <= ( 4096 << 1 ) ), @"Size after inflation exceeds allocated space" ) )
            {
                // Read the compressed data
                range.location += range.length; // Skip over header
                range.length    = blockHeader.sizeCompressed;

                if ( ASSERT( error, range.location + range.length <= compressedData.length, @"Compressed data corrupt" ) )
                {
                    [compressedData readBytes:compressedBlock range:range];
                    
                    // Deflate the data
                    zcpr.next_in   = compressedBlock;
                    zcpr.avail_in  = blockHeader.sizeCompressed;
                    
                    zcpr.next_out  = decompressedBlock;
                    zcpr.avail_out = 4096 << 1; //blockHeader.sizeDecompressed;
                    
                    ret = inflate( &zcpr, Z_SYNC_FLUSH );
                    
                    if ( ret == Z_OK )
                    {
                        [deflatedData appendBytes:decompressedBlock length:zcpr.avail_out]; //blockHeader.sizeDecompressed];
                    }
                    
                    // Skip to next block header
                    range.location += range.length;
                }
            }
        }
    }
    
    // BUGBUG: After decompression, the resultant data should be a multiple of 512 byte sectors.
    //         Frequently, it is not and so it is padded here with zeros to reach a multiple of 512.
    //         Reading past the end of the actual data in the stream could cause errors later.
    if ( deflatedData.length % 512 != 0 )
    {
        int paddingLength = 512 - ( deflatedData.length % 512 );
        
        memset( decompressedBlock, 0, paddingLength );
        
        [deflatedData appendBytes:decompressedBlock length:paddingLength];
    }
    
    free( compressedBlock );
    free( decompressedBlock );
    
    if ( *error )
        return nil;
    else
        return deflatedData;
}

@end
