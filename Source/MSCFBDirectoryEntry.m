//
//  MSCFBDirectoryEntry.m
//
//  Created by Hervey Wilson on 3/11/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBTypes.h"

#import "MSCFBFile.h"
#import "MSCFBFileInternal.h"

#import "MSCFBDirectoryEntry.h"

@implementation MSCFBDirectoryEntry
{
    MSCFB_DIRECTORY_ENTRY *_entry;
    MSCFBFile             *_container;
}

- (id)init:(MSCFB_DIRECTORY_ENTRY *)directoryEntry container:(MSCFBFile *)container
{
    if ( ( self = [super init] ) != nil )
    {
        _entry     = directoryEntry;
        _container = container;
    }
    
    return self;
}

#pragma mark Properties

- (NSString *)name
{
    // cbEntryName is a byte length, not a unichar length and includes the zero terminating unichar
    return [NSString stringWithCharacters:&_entry->szEntryName[0] length:(_entry->cbEntryName - 2) >> 1];
}

- (u_int32_t)left
{
    return _entry->idLeft;
}

- (u_int32_t)right
{
    return _entry->idRight;
}

- (u_int32_t)child
{
    return _entry->idChild;
}

- (Byte)objectType
{
    return _entry->objectType;
}

- (u_int64_t)streamLength
{
    return _entry->streamSize;
}

#pragma mark Methods

- (NSData *)read:(NSRange)range
{
    if ( _entry->streamSize == 0 )
        return nil;
    
    // TODO: Error cases
    // NOTE: If this is the stream for the Root Entry, then it's the mini
    //       stream in the compound file and all reads go through the normal
    //       readStream method rather than the readMiniStream method.
    if ( [self.name isEqualToString:@"Root Entry"] )
    {
        return [_container readStream:_entry->streamStartSector range:range];
    }
    else
    {
        if ( _entry->streamSize > _container.miniStreamCutoffSize )
            return [_container readStream:_entry->streamStartSector range:range];
        else
            return [_container readMiniStream:_entry->streamStartSector range:range];
    }
}

- (NSData *)readAll
{
    if ( _entry->streamSize == 0 )
        return nil;
    
    // TODO: Error cases
    // TODO: Stream size is a u_int64_t
    NSRange range = { 0, _entry->streamSize };
    
    // NOTE: If this is the stream for the Root Entry, then it's the mini
    //       stream in the compound file and all reads go through the normal
    //       readStream method rather than the readMiniStream method.
    //
    //       Otherwise, reads go to either readStream or readMiniStream based
    //       on the length of the target stream.
    if ( [self.name isEqualToString:@"Root Entry"] )
    {
        return [_container readStream:_entry->streamStartSector range:range];
    }
    else
    {
        if ( _entry->streamSize < _container.miniStreamCutoffSize )
            return [_container readMiniStream:_entry->streamStartSector range:range];
        else
            return [_container readStream:_entry->streamStartSector range:range];
    }
}

@end
