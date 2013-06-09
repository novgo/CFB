//
//  MSDRMMessage.m
//  MSCFB
//
//  Created by Hervey Wilson on 3/18/13.
//  Copyright (c) 2013 Microsoft Corp. All rights reserved.
//
#include <zlib.h>

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

@implementation MSDRMMessage
{
    MSDRMFile *_file;
}

#pragma mark - Public Properties

#pragma mark - Public Methods

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    
    if ( error )
        *error = nil;
    
#define ZLIB_BUFFER_SIZE (4 * 1024)
    
#define ZLIB_DRM_HEADER_MAGIC (0x0FA0)
    
    static const unsigned char c_szCompressedDrmMessageHeader[] = { '\x76', '\xE8', '\x04', '\x60', '\xC4', '\x11', '\xE3', '\x86' };
    
    unsigned char szHeader[sizeof(c_szCompressedDrmMessageHeader)] = {0};
    
    [data getBytes:szHeader length:sizeof(szHeader)];
    
    if (memcmp( szHeader, c_szCompressedDrmMessageHeader, sizeof( c_szCompressedDrmMessageHeader) ) != 0)
    {
        return NO;
    }
    
    z_stream zcpr;
    
    BLOCKHEADER    blockHeader = {0};
    Byte *deflatedBlock = malloc( 4096 << 1 ); // Deflated blocks are always less than 4096 bytes
    Byte *inflatedBlock = malloc( 4096 << 1 ); // Inflated blocks are always less than 4096 bytes
    NSRange        range;
    
    NSMutableData *deflatedData = [[NSMutableData alloc] init];
    
    int ret=Z_OK;
    
    memset(&zcpr,0,sizeof(z_stream));
    
    inflateInit(&zcpr);
    
    range.location = sizeof( szHeader );
    
    while ( ret == Z_OK && range.location < data.length )
    {
        // Read the block header
        range.length = sizeof( BLOCKHEADER );
        
        [data getBytes:&blockHeader range:range];
        
        if ( blockHeader.ulCheck != ZLIB_DRM_HEADER_MAGIC )
        {
            printf("Header Check failed!");
            
            free( deflatedBlock );
            free( inflatedBlock );
            
            return NO;
        }
        
        if ( blockHeader.sizeBeforeInflation > 4096 )
        {
            //NSAssert( blockHeader.sizeBeforeInflation <= 4096, @"Size before inflation exceeds allocated space" );
            //NSLog( @"size before exceeds 4096" );
        }
        if ( blockHeader.sizeAfterInflation > 4096 )
        {
            //NSAssert( blockHeader.sizeAfterInflation <= 4096, @"Size after inflation exceeds allocated space" );
            //NSLog( @"size after exceeds 4096" );
        }
        
        // Read the compressed data
        range.location += sizeof( BLOCKHEADER ); // Skip over header
        range.length    = blockHeader.sizeBeforeInflation;
        
        [data getBytes:deflatedBlock range:range];
        
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
        else
        {
            NSAssert( false, @"ret from inflate was %d", ret );
        }
        
        // Skip to next block header
        range.location += blockHeader.sizeBeforeInflation;
    }
    
    free( deflatedBlock );
    free( inflatedBlock );
    
    _file = [[MSDRMFile alloc] initWithData:deflatedData error:error];
    
    [self validate];

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

#pragma mark MSRPMessage methods

- (void)validate
{
    _license          = _file.license;
    _protectedContent = _file.protectedContent;
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
