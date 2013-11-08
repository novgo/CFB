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
    MSCFB_DIRECTORY_ENTRY _entry;
}

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        memset( &_entry, 0, sizeof(MSCFB_DIRECTORY_ENTRY) );
    }
    
    return self;
}

- (id)init:(MSCFB_DIRECTORY_ENTRY *)directoryEntry
{
    if ( ( self = [super init] ) != nil )
    {
        _entry = *directoryEntry;
    }
    
    return self;
}

#pragma mark - Properties

- (NSString *)name
{
    // cbEntryName is a byte length, not a unichar length and includes the zero terminating unichar
    return [NSString stringWithCharacters:&_entry.szEntryName[0] length:(_entry.cbEntryName - 2) >> 1];
}

- (void)setName:(NSString *)name
{
    // Max of 32 unicode characters including zero terminator
    NSAssert( name, @"Directory entry name cannot be nil" );
    NSAssert( name.length <= 31, @"Directory entry name is too long" );
    
    memset( &_entry.szEntryName, 0, sizeof( _entry.szEntryName ) );
    
    _entry.cbEntryName = ( name.length + 1 ) << 1;
    [name getCharacters:&_entry.szEntryName[0]];
}

- (u_int32_t)left
{
    return _entry.idLeft;
}

- (void)setLeft:(u_int32_t)left
{
    _entry.idLeft = left;
}

- (u_int32_t)right
{
    return _entry.idRight;
}

- (void)setRight:(u_int32_t)right
{
    _entry.idRight = right;
}

- (u_int32_t)child
{
    return _entry.idChild;
}

- (void)setChild:(u_int32_t)child
{
    _entry.idChild = child;
}

- (Byte)objectType
{
    return _entry.objectType;
}

- (void)setObjectType:(Byte)objectType
{
    _entry.objectType = objectType;
}

- (u_int64_t)streamStart
{
    return _entry.streamStartSector;
}

- (void)setStreamStart:(u_int64_t)streamStart
{
    _entry.streamStartSector = streamStart;
}

- (u_int64_t)streamLength
{
    return _entry.streamSize;
}

- (void)setStreamLength:(u_int64_t)streamLength
{
    _entry.streamSize = streamLength;
}

#pragma mark - Methods

- (void)getDirectoryEntry:(MSCFB_DIRECTORY_ENTRY *)directoryEntry
{
    NSAssert( directoryEntry, @"Entry cannot be NULL" );
    
    *directoryEntry = _entry;
}

@end
