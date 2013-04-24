//
//  MSCFBTypes.h
//
//  Created by Hervey Wilson on 3/22/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#pragma mark - File Header

typedef struct _MSCFB_Header
{
    u_int32_t signature[2];
    u_int32_t dwClsid[4];
    u_int16_t minorVersion;
    u_int16_t majorVersion;
    u_int16_t byteOrder;
    u_int16_t sectorShift;
    u_int16_t miniSectorShift;
    u_int16_t reserved[3];
    u_int32_t directorySectors;
    u_int32_t fatSectors;
    u_int32_t firstDirectorySector;
    u_int32_t transactionSignature;
    u_int32_t miniStreamCutoff;
    u_int32_t firstMiniFatSector;
    u_int32_t miniFatSectors;
    u_int32_t firstDifatSector;
    u_int32_t difatSectors;
    // Then an array of DIFAT
    u_int32_t difat[109];
} MSCFB_HEADER;

#define MSCFB_SIGNATURE_1 (u_int32_t)0xE011CFD0
#define MSCFB_SIGNATURE_2 (u_int32_t)0xE11AB1A1

#pragma mark - FAT Table

typedef struct _MSCFB_FAT_Sector
{
    u_int32_t nextSector[1];
} MSCFB_FAT_SECTOR;

typedef struct _MSCFB_DIFAT_Sector
{
    u_int32_t sector[1];
} MSCFB_DIFAT_SECTOR;

#define FAT_SECTOR_DIFAT        (u_int32_t)0xFFFFFFFC
#define FAT_SECTOR_SIGNATURE    (u_int32_t)0xFFFFFFFD
#define FAT_SECTOR_END_OF_CHAIN (u_int32_t)0xFFFFFFFE
#define FAT_SECTOR_FREE         (u_int32_t)0xFFFFFFFF

#define SECTOR_SIZE           ( 1 << _header.sectorShift )
#define SECTOR_OFFSET(x)      ( x << _header.sectorShift )
#define MINI_SECTOR_SIZE      ( 1 << _header.miniSectorShift )
#define MINI_SECTOR_OFFSET(x) ( x << _header.miniSectorShift )

#pragma mark - Directory Entry

typedef struct _MSCFB_DirectoryEntry
{
    unichar   szEntryName[32];
    u_int16_t cbEntryName;
    Byte      objectType;
    Byte      color;
    u_int32_t idLeft;
    u_int32_t idRight;
    u_int32_t idChild;
    u_int32_t clsid[4];
    u_int32_t state;
    u_int32_t tmCreate[2];
    u_int32_t tmModified[2];
    u_int32_t streamStartSector;
    u_int64_t streamSize;
} MSCFB_DIRECTORY_ENTRY;

#define CFB_UNKNOWN     0x00
#define CFB_STORAGE     0x01
#define CFB_STREAM      0x02
#define CFB_ROOT_OBJECT 0x05

#define NOSTREAM 0xFFFFFFFF
