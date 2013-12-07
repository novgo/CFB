//
// Copyright (c) 2013 Hervey Wilson. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "CFBTypes.h"
#import "CFBError.h"

#import "CFBDirectoryEntry.h"
#import "CFBFileAllocationTable.h"

#import "CFBObject.h"
#import "CFBObjectInternal.h"

#import "CFBStream.h"
#import "CFBStorage.h"

#import "CFBSource.h"

#import "CFBFile.h"
#import "CFBFileInternal.h"

// Private Interface
@interface CFBFile ()

- (BOOL)createFileAllocationTable:(id<CFBSource>)source error:(NSError * __autoreleasing *)error;
- (BOOL)createDirectory:(id<CFBSource>)source error:(NSError * __autoreleasing *)error;
- (BOOL)createHeader:(id<CFBSource>)source error:(NSError * __autoreleasing *)error;

- (BOOL)loadDirectory:(NSError * __autoreleasing *)error;
- (BOOL)loadFileAllocationTable:(id<CFBSource>)source error:(NSError * __autoreleasing *)error;
- (BOOL)loadHeader:(id<CFBSource>)source error:(NSError * __autoreleasing *)error;
- (BOOL)loadMiniFileAllocationTable:(id<CFBSource>)source error:(NSError * __autoreleasing *)error;
- (CFBStorage *)loadRootStorage;

- (CFBObject *)createObject:(CFBDirectoryEntry *)entry;


@end

@implementation CFBFile
{
    id<CFBSource>   _source;
    MSCFB_HEADER    _header;

    CFBFileAllocationTable *_fat;
    NSMutableData          *_miniFat;
    
    NSMutableArray *_directory;
    
    CFBStorage     *_root;
}

#pragma mark - Class Methods

+ (CFBFile *)compoundFileForReadingAtPath:(NSString *)path
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    CFBFile    *file       = nil;
    
    if ( fileHandle )
        file = [[CFBFile alloc] initWithSource:[[CFBFileSource alloc] initWithFileHandle:fileHandle] error:nil];
    
    return file;
}

+ (CFBFile *)compoundFileForReadingWithData:(NSData *)data
{
    CFBFile *file = [[CFBFile alloc] initWithSource:[[CFBDataSource alloc] initWithData:data] error:nil];
    
    return file;
}

+ (CFBFile *)compoundFileForUpdatingAtPath:(NSString *)path
{
    CFBFile *file = nil;
    
    // To update a file, it must already exist.
    if ( [[NSFileManager defaultManager] fileExistsAtPath:path] )
    {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];
        
        if ( fileHandle )
            file = [[CFBFile alloc] initWithSource:[[CFBMutableFileSource alloc] initWithFileHandle:fileHandle] error:nil];
    }
    
    return file;
}

+ (CFBFile *)compoundFileForWritingAtPath:(NSString *)path
{
    CFBFile       *file        = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSFileHandle  *fileHandle  = nil;
    
    // To write a file, we either create it or truncate it
    if ( [fileManager fileExistsAtPath:path] )
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
        file = [[CFBFile alloc] initForWritingWithSource:[[CFBMutableFileSource alloc] initWithFileHandle:fileHandle] error:nil];
    
    return file;
}

#pragma mark - Public Methods

- (id)init
{
    NSAssert( false, @"Illegal call to init" );
    
    return nil;
}

- (id)initWithSource:(id<CFBSource>)source error:(NSError *__autoreleasing *)error
{
    NSParameterAssert( source != nil );
    
    // Initialize private fields
    _directory = nil;
    _fat       = nil;
    _miniFat   = nil;
    _root      = nil;
    _source    = nil;
    
    NSAssert( source != nil, @"Invalid source" );
    NSAssert( source.length % 512 == 0, @"Invalid source length" );
    
    // Save the source
    _source = source;
    
    // Load the header first
    if ( ![self loadHeader:source error:error] )
    {
        self = nil; return self;
    }

    // Load the FAT
    if ( ![self loadFileAllocationTable:source error:error] )
    {
        self = nil; return self;
    }
    
    // Load the mini FAT
    if ( ![self loadMiniFileAllocationTable:source error:error] )
    {
        self = nil; return self;
    }
    
    // Load the directory
    if ( ![self loadDirectory:error] )
    {
        self = nil; return self;
    }
    
    // NOTE: the root storages stream is actually the mini stream
    _root = [self loadRootStorage];

    return self;
}

- (id)initForWritingWithSource:(id<CFBSource>)source error:(NSError *__autoreleasing *)error
{
    NSParameterAssert( source != nil );
    NSParameterAssert( [source isReadOnly] == NO );
    
    if ( ![self createHeader:source error:error] )
    {
        self = nil; return self;
    }
    
    if ( ![self createFileAllocationTable:source error:error] )
    {
        self = nil; return self;
    }
    
    if ( ![self createDirectory:source error:error] )
    {
        self = nil; return self;
    }
    
    return [self initWithSource:source error:error];
}

- (void)close
{
    [_source close];
}

- (BOOL)isReadOnly
{
    return [_source isReadOnly];
}

- (NSArray *)allKeys
{
    return [_root allKeys];
}

- (NSArray *)allValues
{
    return [_root allValues];
}

- (CFBObject *)objectForKey:(NSString *)key
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
    
    // Calculate the range of sectors that must be read:
    u_int32_t      sectorIndex    = index;
    NSRange        sectorRange    = { range.location >> _header.sectorShift, ( range.length >> _header.sectorShift ) + 1 };
    
    // Follow the chain from the starting sector until we reach the
    // the first sector that must be read. At the end of the loop,
    // sector has the sector number for the start of the read.
    while ( sectorRange.location > 0 && sectorIndex != FAT_SECTOR_END_OF_CHAIN )
    {
        sectorIndex = [_fat nextSectorInChain:sectorIndex];
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
            sectorIndex = [_fat nextSectorInChain:sectorIndex];
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

// Create a new file allocation table
- (BOOL)createFileAllocationTable:(id<CFBSource>)source error:(NSError * __autoreleasing *)error
{
    NSParameterAssert( source != nil );
    NSParameterAssert( [source isReadOnly] == NO );
    
    // Write the first FAT sector
    u_int32_t fatSector[SECTOR_SIZE >> 2];
    
    for ( int i = 0; i < SECTOR_SIZE >> 2; i++ )
        fatSector[i] = FAT_SECTOR_END_OF_CHAIN;
    
    // Write the sector: note that we cannot do a sectorWrite here because _source is not initialized.
    [source writeBytes:&fatSector range:NSMakeRange( SECTOR_OFFSET(_header.difat[0]), SECTOR_SIZE)];

    return YES;
}

// Create a new directory with a root storage
- (BOOL)createDirectory:(id<CFBSource>)source error:(NSError * __autoreleasing *)error
{
    NSParameterAssert( source != nil );
    NSParameterAssert( [source isReadOnly] == NO );
    
    // Bootstrap the Directory and the Root Entry storage
    MSCFB_DIRECTORY_ENTRY directorySector[4];
    CFBDirectoryEntry  *directoryEntry      = [[CFBDirectoryEntry alloc] init];
    
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
    
    // Write the directory entry: note that we cannot do a sectorWrite here because _source is not initialized.
    [source writeBytes:&directorySector range:NSMakeRange( SECTOR_OFFSET( _header.firstDirectorySector ), SECTOR_SIZE )];

    return YES;
}

// Create a header for a new file
- (BOOL)createHeader:(id<CFBSource>)source error:(NSError * __autoreleasing *)error
{
    NSParameterAssert( source != nil );
    NSParameterAssert( [source isReadOnly] == NO );
    
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
    
    _header.miniFatSectors       = 0;
    
    _header.directorySectors     = 0; // Version 3 is zero, Version 4 is a count
    _header.firstDirectorySector = 1; // The first directory sector is 1
    
    // Write the header: note that we cannot do a sectorWrite here because _source is not initialized.
    [source writeBytes:&_header range:NSMakeRange( 0, sizeof(MSCFB_HEADER) )];
    
    return YES;
}

// Initialize the directory
- (BOOL)loadDirectory:(NSError * __autoreleasing *)error
{
    // There are up to 4 directory entries in a directory sector.
    // Additional sectors may exist and are found by following the
    // chain in the FAT sector. Version 4 files have a count of
    // sectors in the header, but version 3 files have that field
    // set to zero.
    u_int32_t sectorCount   = [_fat sectorsInChain:_header.firstDirectorySector];
    NSRange   sectorRange   = { 0, sectorCount << _header.sectorShift };
    NSData   *directoryData = [self readStream:_header.firstDirectorySector range:sectorRange];
    
    _directory = [[NSMutableArray alloc] init];

    MSCFB_DIRECTORY_ENTRY *directoryEntry = (MSCFB_DIRECTORY_ENTRY *)directoryData.bytes;
    
    for ( int i = 0; i < directoryData.length / sizeof(MSCFB_DIRECTORY_ENTRY); ++i )
    {
        if ( directoryEntry[i].cbEntryName != 0 )
        {
            [_directory addObject:[[CFBDirectoryEntry alloc] init:&directoryEntry[i]]];
        }
    }
    
    return YES;
}

// Initialize the File Allocation Table
- (BOOL)loadFileAllocationTable:(id<CFBSource>)source error:(NSError * __autoreleasing *)error
{
    // Save the FAT object
    if ( ( _fat = [[CFBFileAllocationTable alloc] init:self error:error] ) == nil ) return NO;
    
    return YES;
}

- (BOOL)loadHeader:(id<CFBSource>)source error:(NSError * __autoreleasing *)error
{
    [source readBytes:&_header range:NSMakeRange(0, sizeof(MSCFB_HEADER))];
    
    // Verify header signatures
    if ( !ASSERT( error, ( _header.signature[0] == MSCFB_SIGNATURE_1 || _header.signature[1] == MSCFB_SIGNATURE_2 ), @"Invalid signature" ) )
        return NO;
    
    // Verify CLSID
    for ( int i = 0; i < 3; ++i )
    {
        if ( !ASSERT(error, _header.dwClsid[i] == 0, @"Invalid CLSID" ) )
            return NO;
    }
    
    // Verify major version
    if ( !ASSERT( error, _header.majorVersion == 3 || _header.majorVersion == 4, @"Invalid major version" ) )
        return NO;
    
    // Minor Version
    if ( !ASSERT( error, _header.minorVersion == 0x3E, @"Invalid minor version" ) )
        return NO;
    
    // Byte order
    if ( !ASSERT( error, _header.byteOrder == 0xFFFE, @"Invalid byte order" ) )
        return NO;
    
    // Mini sector shift must be 0x0006, and mini sector size is 64
    if ( !ASSERT( error, _header.miniSectorShift == 0x0006, @"Invalid mini sector shift" ) )
        return NO;
    
    // Reserved bytes
    for ( int i = 0; i < 3; ++i )
    {
        if ( !ASSERT( error, _header.reserved[i] == 0, @"Invalid reserved field" ) )
            return NO;
    }
    
    if ( _header.majorVersion == 3 )
    {
        // Sector shift must be 0x0009, and sector size is 512
        if ( !ASSERT( error, _header.sectorShift == 0x0009, @"Invalid sector size for version 3" ) )
            return NO;
    }
    else if ( _header.majorVersion == 4 )
    {
        if ( !ASSERT( error, _header.sectorShift == 0x000C, @"Invalid sector size for version 4" ) )
            return NO;
    }
    
    // Number of directory sectors
    // TODO: Version 4 files may contain a count here
    if ( !ASSERT( error, _header.directorySectors == 0, @"Invalid number of directory sectors" ) )
        return NO;
    
    return YES;
}

- (BOOL)loadMiniFileAllocationTable:(id<CFBSource>)source error:(NSError * __autoreleasing *)error
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
        
        u_int32_t sectorIndex = _header.firstMiniFatSector;
        
        for ( int i = 0; i < _header.miniFatSectors; i++ )
        {
            [miniFat appendData:[self sectorRead:sectorIndex]];
            
            sectorIndex = [_fat nextSectorInChain:sectorIndex];
        }
        
        if ( !ASSERT( error, sectorIndex == FAT_SECTOR_END_OF_CHAIN, @"Expected END_OF_CHAIN sector" ) ) return NO;
        if ( !ASSERT( error, miniFat.length == ( _header.miniFatSectors << _header.sectorShift), @"Did not read enough mini FAT data" ) ) return NO;
        
        _miniFat = miniFat;
    }
    
    return YES;
}

// Initializes the root object
- (CFBStorage *)loadRootStorage
{
    // Get the root directory entry and verify it before loading it
    CFBDirectoryEntry *rootEntry = [self directoryEntryAtIndex:0];
    
    NSAssert( rootEntry.objectType == CFB_ROOT_OBJECT, @"Root must be a storage" );
    NSAssert( [rootEntry.name isEqualToString:@"Root Entry"], @"Root must be named Root Entry" );
    
    // Use the child to find the subtree for the root storage and load all its content
    CFBStorage *root = (CFBStorage *)[self createObject:rootEntry];
    
    [self walkTree:[self directoryEntryAtIndex:rootEntry.child] forStorage:root];
    
    return root;
}

// Initializes an object from a directory entry
- (CFBObject *)createObject:(CFBDirectoryEntry *)directoryEntry
{
    CFBObject *object = nil;
    
    if ( directoryEntry.objectType == 0x01 )
    {
        object = [[CFBStorage alloc] init:directoryEntry container:self];
    }
    else if ( directoryEntry.objectType == 0x02 )
    {
        NSAssert( directoryEntry.child == NOSTREAM, @"Unexpected: stream has a child" );
        
        object = [[CFBStream alloc] init:directoryEntry container:self];
    }
    else if ( directoryEntry.objectType == 0x05 )
    {
        //NSAssert( directoryEntry.child != NOSTREAM, @"Unexpected: storage has no child" );
        
        object = [[CFBStorage alloc] init:directoryEntry container:self];
    }
    
    return object;
}

- (CFBDirectoryEntry *)directoryEntryAtIndex:(NSInteger)index
{
    if ( index == NOSTREAM )
        return nil;
    
    return [_directory objectAtIndex:index];
}

- (NSData *)sectorRead:(NSUInteger)index
{
    // Current sector must be within the FAT range. The number of entries in the FAT
    // is given by _header.fatSectors << _header.sectorShift >> 2. It must also not
    // be a free sector or a DIFAT sector, and definitely not end of chain.
    NSParameterAssert( index < _header.fatSectors << _header.sectorShift >> 2 );
    NSParameterAssert( index != FAT_SECTOR_FREE );
    NSParameterAssert( index != FAT_SECTOR_DIFAT );
    NSParameterAssert( index != FAT_SECTOR_END_OF_CHAIN );
    
    NSAssert( _source, @"No valid source" );
    
    NSData *data = [_source readData:NSMakeRange( SECTOR_OFFSET( index ), SECTOR_SIZE )];
    
    NSAssert( data != nil, @"Did not read any data" );
    NSAssert( data.length == SECTOR_SIZE, @"Did not read a complete sector" );
    
    return data;
}

- (void)sectorWrite:(NSUInteger)index data:(NSData *)data
{
    NSParameterAssert( data != nil );
    NSParameterAssert( data.length == SECTOR_SIZE );

    NSAssert( _source, @"No valid source" );
    NSAssert( [_source isReadOnly] == NO, @"Source is read-only" );
    
    [_source writeData:data location:SECTOR_OFFSET( index )];
}

- (void)walkTree:(CFBDirectoryEntry *)entry forStorage:(CFBStorage *)storage
{
    if ( entry == nil ) return;
    
    CFBObject *object = [self createObject:entry];
    [storage addObject:object];
    
    [self walkTree:[self directoryEntryAtIndex:entry.left] forStorage:storage];
    [self walkTree:[self directoryEntryAtIndex:entry.right] forStorage:storage];
    
    if ( [object isKindOfClass:[CFBStorage class]] )
    {
        [self walkTree:[self directoryEntryAtIndex:entry.child] forStorage:(CFBStorage *)object];
    }
}

@end
