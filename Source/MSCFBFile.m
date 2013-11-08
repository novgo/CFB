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
#import "MSCFBObjectInternal.h"
#import "MSCFBStorage.h"
#import "MSCFBStream.h"

#import "MSCFBSource.h"

#import "MSCFBFile.h"
#import "MSCFBFileInternal.h"

// Private Interface
@interface MSCFBFile ()

- (id)initWithSource:(id<MSCFBSource>)source error:(NSError *__autoreleasing *)error;

- (BOOL)loadDirectory:(NSError * __autoreleasing *)error;
- (BOOL)loadFileAllocationTable:(id<MSCFBSource>)source error:(NSError * __autoreleasing *)error;
- (BOOL)loadMiniFileAllocationTable:(id<MSCFBSource>)source error:(NSError * __autoreleasing *)error;

- (MSCFBObject *)createObject:(MSCFBDirectoryEntry *)entry;
- (MSCFBStorage *)loadRootStorage;

// Sector reading and writing
- (NSData *)sectorRead:(NSUInteger)index;
- (void)sectorWrite:(NSUInteger)index data:(NSData *)data;

@end

@implementation MSCFBFile
{
    MSCFB_HEADER    _header;
    
    NSMutableArray *_directory;
    
    NSMutableData  *_fat;
    NSMutableData  *_miniFat;
    
    id<MSCFBSource> _source;
    
    MSCFBStorage   *_root;
}

#pragma mark - Class Methods

+ (MSCFBFile *)compoundFileForReadingAtPath:(NSString *)path
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    MSCFBFile    *file       = nil;
    
    if ( fileHandle )
        file = [[MSCFBFile alloc] initWithFileHandle:fileHandle error:nil];
    
    return file;
}

+ (MSCFBFile *)compoundFileForReadingWithData:(NSData *)data
{
    MSCFBFile *file = [[MSCFBFile alloc] initWithData:data error:nil];
    
    return file;
}

+ (MSCFBFile *)compoundFileForUpdatingAtPath:(NSString *)path
{
    MSCFBFile *file = nil;
    
    // To update a file, it must already exist.
    if ( [[NSFileManager defaultManager] fileExistsAtPath:path] )
    {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];
        
        if ( fileHandle )
            file = [[MSCFBFile alloc] initWithFileHandle:fileHandle error:nil];
    }
    
    return file;
}

+ (MSCFBFile *)compoundFileForWritingAtPath:(NSString *)path
{
    MSCFBFile     *file        = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSFileHandle  *fileHandle  = nil;
    
    // To write a file, we either create it or truncate it
    if ( ![fileManager fileExistsAtPath:path] )
    {
        // Truncate the file
        fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];
        [fileHandle truncateFileAtOffset:0];

    }
    else
    {
        // Create the file
        [fileManager createFileAtPath:path contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];
    }
    
    if ( fileHandle )
        file = [[MSCFBFile alloc] initForWritingWithFileHandle:fileHandle error:nil];
    
    return file;
}

#pragma mark - Public Methods

- (id)init
{
    NSAssert( false, @"Illegal call to init" );
    
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

- (id)initForWritingWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error
{
    return [self initForWritingWithSource:[[MSCFBFileSource alloc] initWithFileHandle:fileHandle] error:error];
}

- (id)initWithSource:(id<MSCFBSource>)source error:(NSError *__autoreleasing *)error
{
    self = [super init];
    
    if ( !self )
        return nil;
    
    // Initialize private fields
    _directory = nil;
    _fat       = nil;
    _miniFat   = nil;
    _root      = nil;
    _source    = nil;
    
    NSAssert( source != nil, @"Invalid source" );
    NSAssert( source.length % 512 == 0, @"Invalid source length" );
    
    [source readBytes:&_header range:NSMakeRange(0, sizeof(MSCFB_HEADER))];
    
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
    
    // Save the source
    _source = source;

    // Load the FAT
    if ( [self loadFileAllocationTable:source error:error] )
    {
        // Load the mini FAT
        if ( [self loadMiniFileAllocationTable:source error:error] )
        {
            // Load the directory
            if ( [self loadDirectory:error] )
            {
                // NOTE: the root storages stream is actually the mini stream
                _root = [self loadRootStorage];
            }
            else
            {
                // Cleanup
                _miniFat = nil;
                _fat     = nil;
                _source  = nil;
                self     = nil;
            }
        }
        else
        {
            // Cleanup
            _fat    = nil;
            _source = nil;
            self    = nil;
        }
    }
    else
    {
        // Cleanup
        _source = nil;
        self    = nil;
    }

    return self;
}

- (id)initForWritingWithSource:(id<MSCFBSource>)source error:(NSError *__autoreleasing *)error
{
    // Initialize the header and write it
    memset( &_header, 0, sizeof( MSCFB_HEADER ) );
    
    _header.byteOrder        = 0xFFFE;
    
    _header.signature[0]     = MSCFB_SIGNATURE_1;
    _header.signature[1]     = MSCFB_SIGNATURE_2;
    
    _header.dwClsid[0]       = 0;
    _header.dwClsid[1]       = 0;
    _header.dwClsid[2]       = 0;
    _header.dwClsid[3]       = 0;
    
    _header.majorVersion     = 3;
    _header.minorVersion     = 0x3E;

    _header.sectorShift      = 0x0009;
    _header.miniSectorShift  = 0x0006;
    
    _header.reserved[0]      = 0;
    _header.reserved[1]      = 0;
    _header.reserved[2]      = 0;
    
    _header.fatSectors       = 1; // 1 for the Directory Sector
    
    _header.difatSectors     = 0;
    
    // Initialize DIFAT entries
    for ( int i = 0; i < 109; i++ )
    {
        _header.difat[i] = FAT_SECTOR_FREE;
    }
    
    // We must have one FAT sector, locate this in sector 0.
    _header.difat[0] = 0;
    
    _header.miniFatSectors   = 0;
    
    _header.directorySectors     = 0; // Version 3 is zero, Version 4 is a count
    _header.firstDirectorySector = 1; // The first directory sector is 1
    
    // Write the header
    NSData *data = [[NSData alloc] initWithBytesNoCopy:&_header length:sizeof(MSCFB_HEADER) freeWhenDone:NO];
    [source writeData:data location:0];

    // Write the first FAT sector
    u_int32_t fatSector[SECTOR_SIZE >> 2];
    
    for ( int i = 0; i < SECTOR_SIZE >> 2; i++ )
        fatSector[i] = FAT_SECTOR_END_OF_CHAIN;
    
    data = [[NSData alloc] initWithBytesNoCopy:&fatSector length:SECTOR_SIZE freeWhenDone:NO];
    [source writeData:data location:SECTOR_OFFSET(_header.difat[0])];

    // Bootstrap the Directory and the Root Entry storage
    MSCFB_DIRECTORY_ENTRY directorySector[4];
    MSCFBDirectoryEntry  *directoryEntry      = [[MSCFBDirectoryEntry alloc] init];
    
    // First, clear the entire sector
    memset( &directorySector, 0, SECTOR_SIZE );
    
    // Now create an entry for the Root Storage
    directoryEntry.child        = NOSTREAM;
    directoryEntry.left         = NOSTREAM;
    directoryEntry.name         = @"Root Entry";
    directoryEntry.objectType   = CFB_ROOT_OBJECT;
    directoryEntry.right        = NOSTREAM;
    directoryEntry.streamLength = 0;
    directoryEntry.streamStart  = 0;
    
    [directoryEntry getDirectoryEntry:&directorySector[0]];
    
    data = [[NSData alloc] initWithBytesNoCopy:&directorySector[0] length:(sizeof(MSCFB_DIRECTORY_ENTRY) << 2) freeWhenDone:NO];
    
    // Write the header
    [source writeData:data location:SECTOR_OFFSET(_header.firstDirectorySector)];
    
    return [self initWithSource:source error:error];
}

- (void)close
{
    
}

- (NSArray *)allKeys
{
    return [_root allKeys];
}

- (NSArray *)allValues
{
    return [_root allValues];
}

- (MSCFBObject *)objectForKey:(NSString *)key
{
    return [_root objectForKey:key];
}

#pragma mark - Internal Properties

- (MSCFB_HEADER *)header
{
    return &_header;
}

// Mini stream cutoff size
- (u_int32_t)miniStreamCutoffSize
{
    return _header.miniStreamCutoff;
}

#pragma mark - Internal Methods

// Reads range bytes from the stream that starts at the specified sector index.
- (NSData *)readStream:(u_int32_t)index range:(NSRange)range
{
    //DebugLog( @"Stream index: %d, location: %d, length: %d", index, range.location, range.length );
    
    NSUInteger     bytesRemaining = range.length;
    NSMutableData *bytes          = [[NSMutableData alloc] initWithCapacity:range.length];
    
    u_int32_t      sectorIndex    = index;
    NSRange        sectorRange    = { 0, 0 };
    
    // Calculate the range of sectors that must be read
    sectorRange.location = range.location >> _header.sectorShift;
    sectorRange.length   = ( range.length >> _header.sectorShift ) + 1;
    
    const MSCFB_FAT_SECTOR *FAT = [_fat bytes];
    
    // Follow the chain from the starting sector until we reach the
    // the first sector that must be read. At the end of the loop,
    // sector has the sector number for the start of the read.
    while ( sectorRange.location > 0 && sectorIndex != FAT_SECTOR_END_OF_CHAIN )
    {
        sectorIndex = FAT->nextSector[sectorIndex];
        sectorRange.location--;
    }
    
    // If we are not at the end of the chain, then we can start reading data
    if ( sectorIndex != FAT_SECTOR_END_OF_CHAIN )
    {
        NSData  *sector    = nil;
        NSRange  byteRange = { 0, 0 };
        
        // Location is offset into first sector. Length is bytes to read.
        byteRange.location = range.location % SECTOR_SIZE;
        byteRange.length   = ( bytesRemaining < ( SECTOR_SIZE - byteRange.location ) ) ? bytesRemaining : ( SECTOR_SIZE - byteRange.location );
        
        do
        {
            // Read the sector and copy the data
            sector = [self sectorRead:sectorIndex];
            [bytes appendBytes:([sector bytes] + byteRange.location) length:byteRange.length];
            
            // Reduce remaining
            bytesRemaining -= byteRange.length;
            
            // For subsequent sectors, offset into sector is always zero and length
            // is either a complete sector or the remaining bytes.
            byteRange.location = 0;
            byteRange.length   = ( bytesRemaining < SECTOR_SIZE ) ? bytesRemaining : SECTOR_SIZE;
            
            // Point to next sector
            sectorIndex = FAT->nextSector[sectorIndex];
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
    
    // Calculate the range of mini sectors that must be read
    u_int32_t      sectorIndex    = index;
    NSRange        sectorRange    = { range.location >> _header.miniSectorShift, range.length >> _header.miniSectorShift };
    
    const MSCFB_FAT_SECTOR *miniFAT = [_miniFat bytes];
    
    // Follow the chain from the starting sector until we reach the
    // the first sector that must be read. At the end of the loop,
    // sectorIndex has the sector number for the start of the read,
    // sectorRange.location is zero, sectorRange.length is the number of bytes
    // that must be read.
    while ( sectorRange.location > 0 && sectorIndex != FAT_SECTOR_END_OF_CHAIN )
    {
        sectorIndex = miniFAT->nextSector[sectorIndex];
        sectorRange.location--;
    }
    
    // If we are not at the end of the chain, then we can start reading data
    if ( sectorIndex != FAT_SECTOR_END_OF_CHAIN )
    {
        NSRange  byteRange = { 0, 0 };
        
        // Location is offset into first sector. Length is bytes to read.
        // TODO: Check for off-by-one errors
        byteRange.location = range.location % MINI_SECTOR_SIZE;
        byteRange.length   = ( bytesRemaining < ( MINI_SECTOR_SIZE - byteRange.location ) ) ? bytesRemaining : ( MINI_SECTOR_SIZE - byteRange.location );
        
        do
        {
            // Current sector must be within the mini FAT range. The number of sectors in the FAT
            // is given by _miniFat.length >> 2. It must also not be a free sector or a DIFAT sector,
            // and definitely not end of chain.
            NSAssert( sectorIndex < _miniFat.length >> 2, @"Current sector outside mini FAT bounds" );
            NSAssert( sectorIndex != FAT_SECTOR_FREE, @"Current sector is a free sector" );
            NSAssert( sectorIndex != FAT_SECTOR_DIFAT, @"Current sector is a DIFAT sector" );
            NSAssert( sectorIndex != FAT_SECTOR_END_OF_CHAIN, @"Current sector is End of Chain" );
            
            // Copy the data: we need to read the data from the underlying mini stream!
            NSRange readRange = { MINI_SECTOR_OFFSET( sectorIndex ) + byteRange.location, byteRange.length };
            NSData *data      = [self readStream:_root.directoryEntry.streamStart range:readRange];

            NSAssert( data != nil && data.length == readRange.length, @"Incorrect read length" );

            [bytes appendData:data];
            
            // Reduce remaining
            bytesRemaining -= byteRange.length;
            
            // For subsequent sectors, offset into sector is always zero and length
            // is either a complete sector or the remaining bytes.
            byteRange.location = 0;
            byteRange.length   = ( bytesRemaining < MINI_SECTOR_SIZE ) ? bytesRemaining : MINI_SECTOR_SIZE;
            
            // Point to next sector
            sectorIndex = miniFAT->nextSector[sectorIndex];
        }
        while ( bytesRemaining > 0 );
    }
    
    NSAssert( bytes.length == range.length, @"Failed to read correct number of bytes" );
    
    return bytes;
}

#pragma mark - Private Methods

// Initialize the directory
- (BOOL)loadDirectory:(NSError * __autoreleasing *)error
{
    // There are up to 4 directory entries in a directory sector.
    // Additional sectors may exist and are found by following the
    // chain in the FAT sector. Version 4 files have a count of
    // sectors in the header, but version 3 files have that field
    // set to zero.
    u_int32_t sector        = _header.firstDirectorySector;
    u_int32_t sectorCount   = [self sectorsInChain:sector];
    NSRange   sectorRange   = { 0, sectorCount << _header.sectorShift };
    NSData   *directoryData = [self readStream:sector range:sectorRange];
    
    _directory = [[NSMutableArray alloc] init];

    MSCFB_DIRECTORY_ENTRY *directoryEntry = (MSCFB_DIRECTORY_ENTRY *)directoryData.bytes;
    
    for ( int i = 0; i < directoryData.length / sizeof(MSCFB_DIRECTORY_ENTRY); ++i )
    {
        if ( directoryEntry[i].cbEntryName != 0 )
        {
            [_directory addObject:[[MSCFBDirectoryEntry alloc] init:&directoryEntry[i]]];
        }
    }
    
    return YES;
}

// Initialize the File Allocation Table
- (BOOL)loadFileAllocationTable:(id<MSCFBSource>)source error:(NSError * __autoreleasing *)error
{
    if ( !ASSERT( error, _header.fatSectors > 0, @"No FAT sectors in header" ) ) return NO;
    
    // The header tells us the number of FAT sectors and the DIFAT entries
    // point to the individual FAT sectors in the source. If there are more than 109 FAT sectors
    // then there is a DIFAT sector chain pointed to from the header.
    NSMutableData *fat = [[NSMutableData alloc] initWithCapacity:( _header.fatSectors << _header.sectorShift )];
    
    int   i, j;
    
    // Use the DIFAT table in the header to load the first 109 FAT sectors
    for ( i = 0; i < 109 && i < _header.fatSectors; ++i )
    {
        if ( _header.difat[i] == FAT_SECTOR_FREE )
            break;
        
        [fat appendData:[self sectorRead:_header.difat[i]]];
        
        // TODO: The following condition only appears to be true of protected content
        //if ( i == 0 && *((u_int32_t *)fatIndex) != FAT_SECTOR_SIGNATURE )
        //{
        //    NSAssert( false, @"No FAT_SECTOR_SIGNATURE" );
        //}
    }
    
    // Now load DIFAT sectors for additional DIFAT entries. Each DIFAT sector
    // is an array of FAT sector indexes where the last entry in the array
    // is the index of the next DIFAT sector.
    if ( _header.difatSectors > 0 )
    {
        u_int32_t           sectorIndex = _header.firstDifatSector;
        NSData             *sector      = nil;
        MSCFB_DIFAT_SECTOR *difatSector = NULL;
        u_int32_t          *difatNext   = NULL;
        
        for ( i = 0; i < _header.difatSectors; i++ )
        {
            // Last entry in DIFAT sector is the chain pointer
            sector      = [self sectorRead:sectorIndex];
            difatSector = (MSCFB_DIFAT_SECTOR *)[sector bytes];
            difatNext   = &difatSector->sector[SECTOR_SIZE / sizeof( u_int32_t) - 1];
            
            // Read the FAT sectors that the DIFAT points to
            for ( j = 0; j < ( SECTOR_SIZE / sizeof( u_int32_t) - 1 ); j++ )
            {
                if ( difatSector->sector[j] == FAT_SECTOR_FREE )
                    break;
                
                // Read the FAT sector
                [fat appendData:[self sectorRead:difatSector->sector[j]]];
            }
            
            if ( i < _header.difatSectors - 1 )
            {
                if ( !ASSERT( error, *difatNext == FAT_SECTOR_DIFAT, @"Expected DIFAT sector" ) ) return NO;
            }
            else
            {
                if ( !ASSERT( error, *difatNext == FAT_SECTOR_END_OF_CHAIN, @"Expected END_OF_CHAIN sector" ) ) return NO;
            }
            
            sectorIndex = *difatNext;
        }
        
        if ( !ASSERT( error, *difatNext == FAT_SECTOR_END_OF_CHAIN, @"Expected END_OF_CHAIN sector" ) ) return NO;
        if ( !ASSERT( error, i == _header.difatSectors, @"Did not read enough DIFAT sectors" ) ) return NO;
    }
    
    // Save the FAT object
    _fat = fat;
    
    return YES;
}

- (BOOL)loadMiniFileAllocationTable:(id<MSCFBSource>)source error:(NSError * __autoreleasing *)error
{
    if ( !ASSERT( error, _fat != nil, @"FAT should be initialized first" ) ) return NO;
    
    // Default to no mini FAT
    _miniFat = nil;
    
    if ( _header.miniFatSectors > 0 )
    {
        // The header tells us the number of mini FAT sectors and the start
        // sector in the file. Mini FAT sectors are like any other stream
        // and are chained via the FAT table. So we can read them like a
        // stream.
        NSMutableData *miniFat = [[NSMutableData alloc] initWithCapacity:( _header.miniFatSectors << _header.sectorShift)];
        
        // Local pointers and index using bytes
        const MSCFB_FAT_SECTOR *fatTable = [_fat bytes];

        u_int32_t sectorIndex = _header.firstMiniFatSector;
        
        for ( int i = 0; i < _header.miniFatSectors; i++ )
        {
            [miniFat appendData:[self sectorRead:sectorIndex]];
            
            sectorIndex = fatTable->nextSector[sectorIndex];
        }
        
        if ( !ASSERT( error, sectorIndex == FAT_SECTOR_END_OF_CHAIN, @"Expected END_OF_CHAIN sector" ) ) return NO;
        if ( !ASSERT( error, miniFat.length == ( _header.miniFatSectors << _header.sectorShift), @"Did not read enough mini FAT data" ) ) return NO;
        
        _miniFat = miniFat;
    }
    
    return YES;
}

// Initializes the root object
- (MSCFBStorage *)loadRootStorage
{
    // Get the root directory entry and verify it before loading it
    MSCFBDirectoryEntry *rootEntry = [self directoryEntryAtIndex:0];
    
    NSAssert( rootEntry.objectType == CFB_ROOT_OBJECT, @"Root must be a storage" );
    NSAssert( [rootEntry.name isEqualToString:@"Root Entry"], @"Root must be named Root Entry" );
    
    // Use the child to find the subtree for the root storage and load all its content
    MSCFBStorage *root = (MSCFBStorage *)[self createObject:rootEntry];
    
    [self walkTree:[self directoryEntryAtIndex:rootEntry.child] forStorage:root];
    
    return root;
}

// Initializes an object from a directory entry
- (MSCFBObject *)createObject:(MSCFBDirectoryEntry *)directoryEntry
{
    MSCFBObject *object = nil;
    
    if ( directoryEntry.objectType == 0x01 )
    {
        object = [[MSCFBStorage alloc] init:directoryEntry container:self];
    }
    else if ( directoryEntry.objectType == 0x02 )
    {
        NSAssert( directoryEntry.child == NOSTREAM, @"Unexpected: stream has a child" );
        
        object = [[MSCFBStream alloc] init:directoryEntry container:self];
    }
    else if ( directoryEntry.objectType == 0x05 )
    {
        //NSAssert( directoryEntry.child != NOSTREAM, @"Unexpected: storage has no child" );
        
        object = [[MSCFBStorage alloc] init:directoryEntry container:self];
    }
    
    return object;
}

- (MSCFBDirectoryEntry *)directoryEntryAtIndex:(NSInteger)index
{
    if ( index == NOSTREAM )
        return nil;
    
    return [_directory objectAtIndex:index];
}

- (NSData *)sectorRead:(NSUInteger)index
{
    // Current sector must be within the FAT range. The number of entires in the FAT
    // is given by _header.fatSectors << _header.sectorShift >> 2. It must also not be a free sector or a DIFAT sector,
    // and definitely not end of chain.
    NSAssert( index < _header.fatSectors << _header.sectorShift >> 2, @"Sector outside FAT bounds" );
    NSAssert( index != FAT_SECTOR_FREE, @"Sector is a free sector" );
    NSAssert( index != FAT_SECTOR_DIFAT, @"Sector is a DIFAT sector" );
    NSAssert( index != FAT_SECTOR_END_OF_CHAIN, @"Sector is End of Chain" );
    
    NSData *data = [_source readRange:NSMakeRange( SECTOR_OFFSET( index ), SECTOR_SIZE )];
    
    NSAssert( data != nil, @"Did not read any data" );
    NSAssert( data.length == SECTOR_SIZE, @"Did not read a complete sector" );
    
    return data;
}

- (void)sectorWrite:(NSUInteger)index data:(NSData *)data
{
    NSAssert( false, @"Not implemented" );
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

- (void)walkTree:(MSCFBDirectoryEntry *)entry forStorage:(MSCFBStorage *)storage
{
    if ( entry == nil ) return;
    
    MSCFBObject *object = [self createObject:entry];
    [storage addObject:object];
    
    [self walkTree:[self directoryEntryAtIndex:entry.left] forStorage:storage];
    [self walkTree:[self directoryEntryAtIndex:entry.right] forStorage:storage];
    
    if ( [object isKindOfClass:[MSCFBStorage class]] )
    {
        [self walkTree:[self directoryEntryAtIndex:entry.child] forStorage:(MSCFBStorage *)object];
    }
}

@end
