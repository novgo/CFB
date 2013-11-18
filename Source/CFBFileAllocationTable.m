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

#import "CFBError.h"
#import "CFBTypes.h"

#import "CFBFile.h"
#import "CFBFileInternal.h"

#import "CFBFileAllocationTable.h"

#undef SECTOR_SIZE
#undef SECTOR_OFFSET

#define SECTOR_SIZE           ( 1 << header->sectorShift )
#define SECTOR_OFFSET(x)      ( ( x + 1 ) << header->sectorShift )

@implementation CFBFileAllocationTable
{
    CFBFile __weak *_file;
    NSMutableData    *_fat;
}

- (id)init:(CFBFile __weak *)file error:(NSError * __autoreleasing *)error
{
    self = [super init];
    
    if ( self )
    {
        _file = file;
        
        [self load:error];
    }
    
    return self;
}

- (BOOL)load:(NSError * __autoreleasing *)error
{
    MSCFB_HEADER *header = [_file header];
    
    if ( !ASSERT( error, header->fatSectors > 0, @"No FAT sectors in header" ) ) return NO;
    
    // The header tells us the number of FAT sectors. The first 109 FAT sectors are indexed
    // from the header in the DIFAT entries. If there are more than 109 FAT sectors
    // then there is a DIFAT sector chain pointed to from the header.
    NSMutableData *fat = [[NSMutableData alloc] initWithCapacity:( header->fatSectors << header->sectorShift )];
    
    int   i, j;
    
    // Use the DIFAT table in the header to load the first 109 FAT sectors.
    for ( i = 0; i < 109 /*&& i < _header.fatSectors*/; ++i )
    {
        if ( header->difat[i] == FAT_SECTOR_FREE )
            break;
        
        [fat appendData:[_file sectorRead:header->difat[i]]];
        
        // The following condition only appears to be true of protected content
        //if ( i == 0 && *((u_int32_t *)fatIndex) != FAT_SECTOR_SIGNATURE )
        //{
        //    NSAssert( false, @"No FAT_SECTOR_SIGNATURE" );
        //}
    }
    
    // Now load DIFAT sectors for additional DIFAT entries. Each DIFAT sector
    // is an array of FAT sector indexes where the last entry in the array
    // is the index of the next DIFAT sector.
    if ( header->difatSectors > 0 )
    {
        u_int32_t           sectorIndex = header->firstDifatSector;
        NSData             *sector      = nil;
        MSCFB_DIFAT_SECTOR *difatSector = NULL;
        u_int32_t          *difatNext   = NULL;
        
        for ( i = 0; i < header->difatSectors; ++i )
        {
            // Last entry in DIFAT sector is the chain pointer
            sector      = [_file sectorRead:sectorIndex];
            difatSector = (MSCFB_DIFAT_SECTOR *)[sector bytes];
            difatNext   = &difatSector->sector[SECTOR_SIZE / sizeof( u_int32_t) - 1];
            
            // Read the FAT sectors that the DIFAT points to
            for ( j = 0; j < ( SECTOR_SIZE / sizeof( u_int32_t) - 1 ); j++ )
            {
                if ( difatSector->sector[j] == FAT_SECTOR_FREE )
                    break;
                
                // Read the FAT sector
                [fat appendData:[_file sectorRead:difatSector->sector[j]]];
            }
            
            if ( i < header->difatSectors - 1 )
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
        if ( !ASSERT( error, i == header->difatSectors, @"Did not read enough DIFAT sectors" ) ) return NO;
    }
    
    // Save the FAT object
    _fat = fat;
    
    return YES;
}

- (u_int32_t)nextSectorInChain:(u_int32_t)index
{
    const MSCFB_FAT_SECTOR *sector = [_fat bytes];
    
    return sector->nextSector[index];
}

- (u_int32_t)sectorsInChain:(u_int32_t)startIndex
{
    const MSCFB_FAT_SECTOR *sector = [_fat bytes];
    
    u_int32_t count = 1;
    
    while ( ( startIndex = sector->nextSector[startIndex] ) != FAT_SECTOR_END_OF_CHAIN )
    {
        count++;
    }
    
    return count;
}


@end
