//
//  MSCompoundFile.m
//
//  Created by Hervey Wilson on 3/6/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBTypes.h"
#import "MSCFBError.h"

#import "MSCFBDirectoryEntry.h"

#import "MSCFBObject.h"
#import "MSCFBStorage.h"
#import "MSCFBStream.h"

#import "MSCFBSource.h"

#import "MSCFBFile.h"
#import "MSCFBFileInternal.h"

// Private Interface
@interface MSCFBFile ()

- (id)initWithSource:(id<MSCFBSource>)source error:(NSError *__autoreleasing *)error;

- (void)loadDirectory;
- (void)loadFAT;
- (void)loadMiniFAT;

@end

@implementation MSCFBFile
{
    MSCFB_HEADER    _header;
    
    NSMutableArray *_directory;
    NSData         *_directoryData;
    
    NSMutableData  *_fat;
    NSMutableData  *_miniFat;
    
    id<MSCFBSource> _source;
    
    MSCFBStorage   *_root;
}

- (id)init
{
    return nil;
}

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    return [self initWithSource:[[MSCFBDataSource alloc] initWithData:data] error:error];
}

- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error
{
    return [self initWithSource:[[MSCFBFileSource alloc] initWithFileHandle:fileHandle] error:error];
}

- (id)initWithSource:(id<MSCFBSource>)source error:(NSError *__autoreleasing *)error
{
    self = [super init];
    
    if ( !self )
        return nil;
    
    _source = source;
    
    [_source getBytes:&_header range:NSMakeRange(0, sizeof(MSCFB_HEADER))];
    
    // Verify header signatures
    if ( !ASSERT( error, ( _header.signature[0] == MSCFB_SIGNATURE_1 || _header.signature[1] == MSCFB_SIGNATURE_2 ), @"Invalid signature" ) )
        return nil;
    
    // Verify CLSID
    for ( int i = 0; i < 3; i++ )
    {
        if ( !ASSERT(error, _header.dwClsid[i] == 0, @"Invalid CLSID" ) )
            return nil;
    }
    
    // Verify major version
    if ( !ASSERT( error, _header.majorVersion == 3 || _header.majorVersion == 4, @"Invalid major version" ) )
        return nil;
    
    // Minor Version
    if ( !ASSERT( error, _header.minorVersion == 0x3E, @"Invalid minor version" ) )
        return nil;
    
    // Byte order
    if ( !ASSERT( error, _header.byteOrder == 0xFFFE, @"Invalid byte order" ) )
        return nil;
    
    // Mini sector shift must be 0x0006, and mini sector size is 64
    if ( !ASSERT( error, _header.miniSectorShift == 0x0006, @"Invalid mini sector shift" ) )
        return nil;
    
    // Reserved bytes
    for ( int i = 0; i < 3; i++ )
    {
        if ( !ASSERT( error, _header.reserved[i] == 0, @"Invalid reserved field" ) )
            return nil;
    }
    
    if ( _header.majorVersion == 3 )
    {
        // Sector shift must be 0x0009, and sector size is 512
        if ( !ASSERT( error, _header.sectorShift == 0x0009, @"Invalid sector size for version 3" ) )
            return nil;
    }
    else if ( _header.majorVersion == 4 )
    {
        if ( !ASSERT( error, _header.sectorShift == 0x000C, @"Invalid sector size for version 4" ) )
            return nil;
    }
    
    // Number of directory sectors
    if ( !ASSERT( error, _header.directorySectors == 0, @"Invalid number of directory sectors" ) )
        return nil;
    
    // Load the FAT
    [self loadFAT];
    
    // Load the mini FAT
    [self loadMiniFAT];
    
    // Load the directory
    [self loadDirectory];
    
    
    // NOTE: the root storages stream is actually the mini stream
    _root = [self initializeRoot];

    return self;
}

- (MSCFBObject *)objectForKey:(NSString *)key
{
    return [_root objectForKey:key];
}

#pragma mark Internal Properties

// Mini stream cutoff size
- (u_int32_t)miniStreamCutoffSize
{
    return _header.miniStreamCutoff;
}

#pragma mark Internal Methods

// Reads range bytes from the stream that starts at the specified sector index.
- (NSData *)readStream:(u_int32_t)index range:(NSRange)range
{
    //DebugLog( @"Stream index: %d, location: %d, length: %d", index, range.location, range.length );
    
    NSUInteger     bytesRemaining = range.length;
    NSMutableData *bytes          = [[NSMutableData alloc] initWithCapacity:range.length];
    u_int32_t      sector         = index;
    NSRange        sectorRange    = { 0, 0 };
    
    // Calculate the range of sectors that must be read
    // TODO: Check for off-by-one errors
    sectorRange.location = range.location >> _header.sectorShift;
    sectorRange.length   = ( range.length >> _header.sectorShift ) + 1;
    
    const MSCFB_FAT_SECTOR *fatTable = [_fat bytes];
    
    // Follow the chain from the starting sector until we reach the
    // the first sector that must be read. At the end of the loop,
    // sector has the sector number for the start of the read.
    while ( sectorRange.location > 0 && sector != FAT_SECTOR_END_OF_CHAIN )
    {
        sector = fatTable->nextSector[sector];
        sectorRange.location--;
    }
    
    // If we are not at the end of the chain, then we can start reading data
    if ( sector != FAT_SECTOR_END_OF_CHAIN )
    {
        NSRange byteRange = { 0, 0 };
        
        // Location is offset into first sector. Length is bytes to read.
        // TODO: Check for off-by-one errors
        byteRange.location = range.location % SECTOR_SIZE;
        byteRange.length   = ( bytesRemaining < ( SECTOR_SIZE - byteRange.location ) ) ? bytesRemaining : ( SECTOR_SIZE - byteRange.location );
        
        do
        {
            // Current sector must be within the FAT range. The number of sectors in the FAT
            // is given by _fatSize >> 2. It must also not be a free sector or a DIFAT sector,
            // and definitely not end of chain.
            NSAssert( sector < _fat.length >> 2, @"Current sector outside FAT bounds" );
            NSAssert( sector != FAT_SECTOR_FREE, @"Current sector is a free sector" );
            NSAssert( sector != FAT_SECTOR_DIFAT, @"Current sector is a DIFAT sector" );
            NSAssert( sector != FAT_SECTOR_END_OF_CHAIN, @"Current sector is End of Chain" );
            
            // Copy the data
            [bytes appendData:[_source readRange:NSMakeRange( SECTOR_OFFSET(sector) + byteRange.location, byteRange.length)]];
            
            // Reduce remaining
            bytesRemaining -= byteRange.length;
            
            // For subsequent sectors, offset into sector is always zero and length
            // is either a complete sector or the remaining bytes.
            byteRange.location = 0;
            byteRange.length   = ( bytesRemaining < SECTOR_SIZE ) ? bytesRemaining : SECTOR_SIZE;
            
            // Point to next sector
            sector = fatTable->nextSector[sector];
        }
        while ( bytesRemaining > 0 );
    }
    
    NSAssert( bytes.length == range.length, @"Failed to read correct number of bytes" );
    
    return bytes;
}

// Reads range bytes from the mini stream with start mini sector index
- (NSData *)readMiniStream:(u_int32_t)index range:(NSRange)range
{
    //DebugLog( @"Stream index: %d, location: %d, length: %d", index, range.location, range.length );
    
    NSUInteger     bytesRemaining = range.length;
    NSMutableData *bytes          = [[NSMutableData alloc] initWithCapacity:range.length];
    u_int32_t      sector         = index;
    NSRange        sectorRange    = { 0, 0 };
    
    // Calculate the range of sectors that must be read
    // TODO: Check for off-by-one errors
    sectorRange.location = range.location >> _header.miniSectorShift;
    sectorRange.length   = ( range.length >> _header.miniSectorShift );
    
    const MSCFB_FAT_SECTOR *fatTable = [_miniFat bytes];
    
    // Follow the chain from the starting sector until we reach the
    // the first sector that must be read. At the end of the loop,
    // sector has the sector number for the start of the read.
    while ( sectorRange.location > 0 && sector != FAT_SECTOR_END_OF_CHAIN )
    {
        sector = fatTable->nextSector[sector];
        sectorRange.location--;
    }
    
    // If we are not at the end of the chain, then we can start reading data
    if ( sector != FAT_SECTOR_END_OF_CHAIN )
    {
        NSRange byteRange = { 0, 0 };
        
        // Location is offset into first sector. Length is bytes to read.
        // TODO: Check for off-by-one errors
        byteRange.location = range.location % MINI_SECTOR_SIZE;
        byteRange.length   = ( bytesRemaining < ( MINI_SECTOR_SIZE - byteRange.location ) ) ? bytesRemaining : ( MINI_SECTOR_SIZE - byteRange.location );
        
        do
        {
            // Current sector must be within the mini FAT range. The number of sectors in the FAT
            // is given by _fatSize >> 2. It must also not be a free sector or a DIFAT sector,
            // and definitely not end of chain.
            NSAssert( sector < _miniFat.length >> 2, @"Current sector outside mini FAT bounds" );
            NSAssert( sector != FAT_SECTOR_FREE, @"Current sector is a free sector" );
            NSAssert( sector != FAT_SECTOR_DIFAT, @"Current sector is a DIFAT sector" );
            NSAssert( sector != FAT_SECTOR_END_OF_CHAIN, @"Current sector is End of Chain" );
            
            // Copy the data: we need to read the data from the underlying mini stream!
            NSRange readRange = { 0, 0 };
            readRange.location = MINI_SECTOR_OFFSET( sector ) + byteRange.location;
            readRange.length   = byteRange.length;
            
            NSData *data = [_root read:readRange];
            
            NSAssert( data != nil && data.length == readRange.length, @"Incorrect read length" );
            [bytes appendData:data];
            //[bytes appendBytes:(dataBytes + MINI_SECTOR_OFFSET( sector ) + byteRange.location) length:byteRange.length];
            
            // Reduce remaining
            bytesRemaining -= byteRange.length;
            
            // For subsequent sectors, offset into sector is always zero and length
            // is either a complete sector or the remaining bytes.
            byteRange.location = 0;
            byteRange.length   = ( bytesRemaining < MINI_SECTOR_SIZE ) ? bytesRemaining : MINI_SECTOR_SIZE;
            
            // Point to next sector
            sector = fatTable->nextSector[sector];
        }
        while ( bytesRemaining > 0 );
    }
    
    NSAssert( bytes.length == range.length, @"Failed to read correct number of bytes" );
    
    return bytes;
}

#pragma mark Private Methods

- (void)loadDirectory
{
    // There are up to 4 directory entries in a directory sector.
    // Additional sectors may exist and are found by following the
    // chain in the FAT sector. Version 4 files have a count of
    // sectors in the header, but version 3 files have that field
    // set to zero.
    u_int32_t sector        = _header.firstDirectorySector;
    u_int32_t sectorCount   = [self sectorsInChain:sector];
    NSRange   sectorRange   = { 0, sectorCount << _header.sectorShift };
    
    _directory     = [[NSMutableArray alloc] init];
    _directoryData = [self readStream:sector range:sectorRange];
    
    MSCFB_DIRECTORY_ENTRY *directoryEntry = (MSCFB_DIRECTORY_ENTRY *)_directoryData.bytes;
    
    for ( int i = 0; i < _directoryData.length / sizeof(MSCFB_DIRECTORY_ENTRY); ++i )
    {
        if ( directoryEntry[i].cbEntryName != 0 )
        {
            [_directory addObject:[[MSCFBDirectoryEntry alloc] init:&directoryEntry[i] container:self]];
        }
    }
}

// Load the FAT table
- (void)loadFAT
{
    NSAssert( _header.fatSectors > 0, @"No FAT sectors in header" );
    
    // The header tells us the number of FAT sectors and the DIFAT entries
    // tell us the sector numbers within the file.
    _fat = [[NSMutableData alloc] initWithCapacity:( _header.fatSectors << _header.sectorShift)];
    [_fat setLength:( _header.fatSectors << _header.sectorShift)];
    
    // Local pointers and index using bytes
    Byte *fatIndex = (Byte *)[_fat bytes];
    int   i, j;
    
    NSRange dataRange = { 0, SECTOR_SIZE };
    
    // Use the DIFAT table in the header to load the first 109 FAT sectors
    for ( i = 0; i < 109 && i < _header.fatSectors; ++i )
    {
        if ( _header.difat[i] == FAT_SECTOR_FREE )
            break;
        
        // Set location in data for current sector
        dataRange.location = SECTOR_OFFSET( _header.difat[i] );
        
        NSAssert( fatIndex - (Byte *)[_fat bytes] < _fat.length, @"Attempt to read past end of FAT space" );
        NSAssert( dataRange.location + dataRange.length < _source.length, @"Attempt to read past end of data" );
        
        [_source getBytes:fatIndex range:dataRange];
        
        // TODO: The following condition only appears to be true of protected content
        //if ( i == 0 && *((u_int32_t *)fatIndex) != FAT_SECTOR_SIGNATURE )
        //{
        //    NSAssert( false, @"No FAT_SECTOR_SIGNATURE" );
        //}
        
        fatIndex += SECTOR_SIZE;
    }
    
    // Now load DIFAT sectors
    if ( _header.difatSectors > 0 )
    {
        dataRange.location = SECTOR_OFFSET( _header.firstDifatSector );
        
        // Last entry in DIFAT sector is the chain pointer
        MSCFB_DIFAT_SECTOR *difatSector = malloc( SECTOR_SIZE );
        u_int32_t        *difatNext   = &difatSector->sector[SECTOR_SIZE / sizeof( u_int32_t) - 1];
        
        for ( i = 0; i < _header.difatSectors; i++ )
        {
            NSAssert( dataRange.location + dataRange.length < _source.length, @"Attempt to read past end of data" );
            [_source getBytes:difatSector range:dataRange];
            
            // Read the FAT sectors that the DIFAT points to
            for ( j = 0; j < ( SECTOR_SIZE / sizeof( u_int32_t) - 1 ); j++ )
            {
                if ( difatSector->sector[j] == FAT_SECTOR_FREE )
                    break;
                
                // Read the FAT sector
                dataRange.location = SECTOR_OFFSET( difatSector->sector[j] );
                
                
                NSAssert( fatIndex - (Byte *)[_fat bytes] < _fat.length, @"Attempt to read past end of FAT space" );
                NSAssert( dataRange.location + dataRange.length < _source.length, @"Attempt to read past end of data" );
                
                [_source getBytes:fatIndex range:dataRange];
                
                fatIndex += SECTOR_SIZE;
            }
            
            if ( i < _header.difatSectors - 1 )
                NSAssert( *difatNext == FAT_SECTOR_DIFAT, @"Expected DIFAT sector" );
            else
                NSAssert( *difatNext == FAT_SECTOR_END_OF_CHAIN, @"Expected END_OF_CHAIN sector" );
            
            dataRange.location = SECTOR_OFFSET( *difatNext );
        }
        
        NSAssert( *difatNext == FAT_SECTOR_END_OF_CHAIN, @"Expected END_OF_CHAIN sector" );
        NSAssert( i == _header.difatSectors, @"Did not read enough DIFAT sectors" );
        
        free( difatSector );
    }
}

- (void)loadMiniFAT
{
    if ( _header.miniFatSectors > 0 )
    {
        // The header tells us the number of mini FAT sectors and the start
        // sector in the file. Mini FAT sectors are like any other stream
        // and are chained via the FAT table. So we can read them like a
        // stream.
        _miniFat = [[NSMutableData alloc] initWithCapacity:( _header.miniFatSectors << _header.sectorShift)];
        
        // Local pointers and index using bytes
        const MSCFB_FAT_SECTOR *fatTable = [_fat bytes];

        u_int32_t sector    = _header.firstMiniFatSector;
        NSRange   dataRange = { SECTOR_OFFSET( sector ), SECTOR_SIZE };
        int       i         = 0;
        
        for ( i = 0; i < _header.miniFatSectors; i++ )
        {
            NSAssert( dataRange.location + dataRange.length < _source.length, @"Attempt to read past end of data" );
            [_miniFat appendData:[_source readRange:dataRange]];
            
            sector             = fatTable->nextSector[sector];
            dataRange.location = SECTOR_OFFSET( sector );
        }
        
        NSAssert( sector == FAT_SECTOR_END_OF_CHAIN, @"Expected END_OF_CHAIN sector" );
        NSAssert( i == _header.miniFatSectors, @"Did not read enough mini FAT sectors" );
        NSAssert( _miniFat.length == ( _header.miniFatSectors << _header.sectorShift), @"Did not read enough mini FAT data" );
    }
    else
    {
        _miniFat = nil;
    }
}

// Reads data from the real file
- (NSData *)read:(NSRange)range
{
    return [_source readRange:range];
}

- (MSCFBDirectoryEntry *)directoryEntryAtIndex:(NSInteger)index
{
    if ( index == NOSTREAM )
        return nil;
    
    return [_directory objectAtIndex:index];
}

- (u_int32_t)sectorsInChain:(u_int32_t)startIndex
{
    const MSCFB_FAT_SECTOR *fatTable = [_fat bytes];
    
    u_int32_t count = 1;
    
    while ( ( startIndex = fatTable->nextSector[startIndex] ) != FAT_SECTOR_END_OF_CHAIN )
    {
        count++;
    }
    
    return count;
}

// Initializes an object from a directory entry
- (MSCFBObject *)initializeObject:(MSCFBDirectoryEntry *)directoryEntry
{
    MSCFBObject *object = nil;
    
    if ( directoryEntry.objectType == 0x01 )
    {
        object = [[MSCFBStorage alloc] init:directoryEntry];
    }
    else if ( directoryEntry.objectType == 0x02 )
    {
        NSAssert( directoryEntry.child == NOSTREAM, @"Unexpected: stream has a child" );
        
        object = [[MSCFBStream alloc] init:directoryEntry];
    }
    else if ( directoryEntry.objectType == 0x05 )
    {
        NSAssert( directoryEntry.child != NOSTREAM, @"Unexpected: storage has no child" );
        
        object = [[MSCFBStorage alloc] init:directoryEntry];
    }
    
    return object;
}

// Initializes the root object
- (MSCFBStorage *)initializeRoot
{
    // Get the root directory entry and verify it before loading it
    MSCFBDirectoryEntry *rootEntry = [self directoryEntryAtIndex:0];
    
    NSAssert( rootEntry.objectType == CFB_ROOT_OBJECT, @"Root must be a storage" );
    NSAssert( [rootEntry.name isEqualToString:@"Root Entry"], @"Root must be named Root Entry" );

    // Use the child to find the subtree for the root storage and load all its content
    MSCFBStorage *root = (MSCFBStorage *)[self initializeObject:rootEntry];
    
    [self walkTree:[self directoryEntryAtIndex:rootEntry.child] forStorage:root];
    
    return root;
}

- (void)walkTree:(MSCFBDirectoryEntry *)entry forStorage:(MSCFBStorage *)storage
{
    if ( entry == nil ) return;
    
    MSCFBObject *object = [self initializeObject:entry];
    [storage addObject:object];
    
    [self walkTree:[self directoryEntryAtIndex:entry.left] forStorage:storage];
    [self walkTree:[self directoryEntryAtIndex:entry.right] forStorage:storage];
    
    if ( [object isKindOfClass:[MSCFBStorage class]] )
    {
        [self walkTree:[self directoryEntryAtIndex:entry.child] forStorage:(MSCFBStorage *)object];
    }
}

@end
