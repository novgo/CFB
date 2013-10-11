//
//  MSDRMFile.m
//
//  Created by Hervey Wilson on 4/23/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSDRMFile.h"

#pragma mark - Implementation constants

static const unichar _DRMContent[]       = { '\x9', 'D', 'R', 'M', 'C', 'o', 'n', 't', 'e', 'n', 't' };
static const unichar _DRMDataSpace[]     = { '\x9', 'D', 'R', 'M', 'D', 'a', 't', 'a', 'S', 'p', 'a', 'c', 'e' };
static const unichar _DRMTransform[]     = { '\x9', 'D', 'R', 'M', 'T', 'r', 'a', 'n', 's', 'f', 'o', 'r', 'm' };
static const unichar _DataSpaces[]       = { '\x6', 'D', 'a', 't', 'a', 'S', 'p', 'a', 'c', 'e', 's' };
static const unichar _EncryptedPackage[] = { 'E', 'n', 'c', 'r', 'y', 'p', 't', 'e', 'd', 'P', 'a', 'c', 'k', 'a', 'g', 'e' };
static const unichar _Primary[]          = { '\x6', 'P', 'r', 'i', 'm', 'a', 'r', 'y' };


@interface MSDRMFile ()

- (BOOL)validate:(NSError *__autoreleasing *)error;

@end

@implementation MSDRMFile

#pragma mark - Public Methods

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    _license                = nil;
    _protectedContent       = nil;
    _protectedContentLength = 0;
    
    if ( ( self = [super initWithData:data error:error] ) != nil )
    {
        self = [self validate:error] ? self : nil;
    }
    
    return self;
}

- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    _license                = nil;
    _protectedContent       = nil;
    _protectedContentLength = 0;
    
    if ( ( self = [super initWithFileHandle:fileHandle error:error] ) != nil )
    {
        self = [self validate:error] ? self : nil;
    }
    
    return self;
}

#pragma mark - Private Methods

- (BOOL)validate:(NSError *__autoreleasing *)error
{
    if ( error ) *error = nil;
        
    NSString *DRMContent            = [NSString stringWithCharacters:_DRMContent length:sizeof(_DRMContent) >> 1];
    NSString *DRMDataSpace          = [NSString stringWithCharacters:_DRMDataSpace length:sizeof(_DRMDataSpace) >> 1];
    NSString *DRMTransform          = [NSString stringWithCharacters:_DRMTransform length:sizeof(_DRMTransform) >> 1];
    NSString *DataSpaces            = [NSString stringWithCharacters:_DataSpaces length:sizeof(_DataSpaces) >> 1];
    NSString *EncryptedPackage      = @"EncryptedPackage";
    NSString *Primary               = [NSString stringWithCharacters:_Primary length:sizeof(_Primary) >> 1];
    NSString *Version               = @"Version";
    NSString *DataSpaceMap          = @"DataSpaceMap";
    NSString *DataSpaceInfo         = @"DataSpaceInfo";
    NSString *TransformInfo         = @"TransformInfo";
    NSString *DRMEncryptedTransform = @"DRMEncryptedTransform";
    
    // Validate the structure of the file.
    MSCFBObject    *cfbObject;
    MSCFBStorage   *cfbStorage;
    MSCFBStream    *cfbStream;
    
    // ECMA content has an EncryptedPackage stream; otherwise a DRMContent stream
    cfbObject = [self objectForKey:EncryptedPackage];
    
    if ( cfbObject != nil )
    {
        // ECMA Content
        if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStream class]], @"EncryptedPackage object is not a stream" ) ) return NO;
        
        cfbStream = (MSCFBStream *)cfbObject;
        
        // The first 8 bytes of the EncryptedPackage stream are the length of the *plaintext* data, not the encrypted data
        u_int64_t contentLength = 0;
        [[cfbStream read:NSMakeRange(0, 8)] getBytes:&contentLength length:8];
        //NSAssert( contentLength == cfbStream.length - 8, @"Incorrect EncryptedPackage length" );
        
        _protectedContent       = [cfbStream read:NSMakeRange( 8, cfbStream.length - 8 )];
        _protectedContentLength = contentLength;
    }
    else
    {
        // DRM Content
        cfbObject = [self objectForKey:DRMContent];
        if ( !ASSERT( error, cfbObject != nil, @"Missing DRMContent stream" ) ) return NO;
        if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStream class]], @"DRMContent object is not a stream" ) ) return NO;

        cfbStream = (MSCFBStream *)cfbObject;
        
        // The first 8 bytes of the DRMContent stream are the length
        u_int64_t contentLength = 0;
        [[cfbStream read:NSMakeRange(0, 8)] getBytes:&contentLength length:8];
        if ( !ASSERT( error, contentLength == cfbStream.length - 8, @"Incorrect DRMContent length" ) ) return NO;
        
        // TODO: What does contentLength mean in this case?
        _protectedContent       = [cfbStream read:NSMakeRange( 8, cfbStream.length - 8 )];
        _protectedContentLength = contentLength;
    }
    
    // Back to root: must have a DataSpaces storage
    cfbObject = [self objectForKey:DataSpaces];
    if ( !ASSERT( error, cfbObject != nil, @"Missing DataSpaces storage" ) ) return NO;
    if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStorage class]], @"DataSpace object is not a storage" ) ) return NO;
    
    cfbStorage = (MSCFBStorage *)cfbObject;
    
    // DataSpaces must have a Version stream
    cfbObject = [cfbStorage objectForKey:Version];
    if ( !ASSERT( error, cfbObject != nil, @"Missing Version stream" ) ) return NO;
    if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStream class]], @"Version object is not a stream" ) ) return NO;
    
    // DataSpaces must have a DataSpaceMap stream
    cfbObject = [cfbStorage objectForKey:DataSpaceMap];
    
    if ( !ASSERT( error, cfbObject != nil, @"Missing DataSpaceMap stream" ) ) return NO;
    if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStream class]], @"DataSpaceMap object is not a stream" ) ) return NO;
    
    // DataSpaces must have a DataSpaceInfo storage
    cfbObject = [cfbStorage objectForKey:DataSpaceInfo];

    if ( !ASSERT( error, cfbObject != nil, @"Missing DataSpaceInfo storage" ) ) return NO;
    if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStorage class]], @"DataSpaceInfo object is not a storage" ) ) return NO;
    
    // DataSpaces must have a TranformInfo storage
    cfbObject = [cfbStorage objectForKey:TransformInfo];
    if ( !ASSERT( error, cfbObject != nil, @"Missing TransformInfo storage" ) ) return NO;
    if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStorage class]], @"TransformInfo object is not a storage" ) ) return NO;
    
    cfbStorage = (MSCFBStorage *)cfbObject;
    
    // TranformInfo must have a DRMEncryptedTransform storage for ECMA content or a DRMTransform for binary
    if ( [self objectForKey:EncryptedPackage] != nil )
    {
        cfbObject = [cfbStorage objectForKey:DRMEncryptedTransform];
        if ( !ASSERT( error, cfbObject != nil, @"Missing DRMEncryptedTransform storage" ) ) return NO;
        if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStorage class]], @"DRMEncryptedTransform object is not a storage" ) ) return NO;
        
        cfbStorage = (MSCFBStorage *)cfbObject;
        
        // DRMEncryptedTransform must have a Primary stream
        cfbObject = [cfbStorage objectForKey:Primary];
        if ( !ASSERT( error, cfbObject != nil, @"Missing Primary stream" ) ) return NO;
        if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStream class]], @"Primary object is not a stream" ) ) return NO;
        
        cfbStream = (MSCFBStream *)cfbObject;
    }
    else
    {
        // TranformInfo must have a DRMTransform storage
        cfbObject = [cfbStorage objectForKey:DRMTransform];
        if ( !ASSERT( error, cfbObject != nil, @"Missing DRMTransform storage" ) ) return NO;
        if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStorage class]], @"DRMTransform object is not a storage" ) ) return NO;
        
        cfbStorage = (MSCFBStorage *)cfbObject;
        
        // DRMTransform must have a Primary stream
        cfbObject = [cfbStorage objectForKey:Primary];
        if ( !ASSERT( error, cfbObject != nil, @"Missing Primary stream" ) ) return NO;
        if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStream class]], @"Primary object is not a stream" ) ) return NO;
        
        cfbStream = (MSCFBStream *)cfbObject;
    }
    
    // TODO: Consider just grabbing all the primary into memory and walking through it
    
    // Now try to unpack the Primary
    NSRange readRange = { 0, 0 };
    
    struct
    {
        u_int32_t cbTransformInfo;
        u_int32_t transformInfoType;
        u_int32_t cbTransformID;      // Length in bytes of unicode string; i.e. length >> 1 characters
    } transformInfoHeader;
    
    readRange.length   = 12;
    readRange.location = 0;
    [[cfbStream read:readRange] getBytes:&transformInfoHeader length:readRange.length];
    
    // TODO: Watch for UNICODE-LP padding!
    
    readRange.location += readRange.length;
    readRange.length    = transformInfoHeader.cbTransformID;
    NSString *transformID = [[NSString alloc] initWithCharacters:[[cfbStream read:readRange] bytes] length:readRange.length >> 1];
    if ( !ASSERT( error, [transformID isEqualToString:@"{C73DFACD-061F-43B0-8B64-0C620D2A8B50}"], @"Invalid transform id" ) ) return NO;
    
    // Alignment
    u_int32_t paddedLength = transformInfoHeader.cbTransformID;
    if ( paddedLength >> 2 << 2 != paddedLength )
        paddedLength += 2;
    
    u_int32_t cbTransformName = 0;
    
    readRange.location += paddedLength;
    readRange.length    = sizeof( u_int32_t );
    [[cfbStream read:readRange] getBytes:&cbTransformName length:readRange.length];
    
    readRange.location += readRange.length;
    readRange.length    = cbTransformName;
    NSString *transformName = [[NSString alloc] initWithCharacters:[[cfbStream read:readRange] bytes] length:readRange.length >> 1];
    if ( !ASSERT( error, [transformName isEqualToString:@"Microsoft.Metadata.DRMTransform"], @"Invalid transform name" ) ) return NO;
    
    // Alignment
    paddedLength = cbTransformName;
    if ( paddedLength >> 2 << 2 != paddedLength )
        paddedLength += 2;
    
    struct
    {
        u_int16_t readerMajor;
        u_int16_t readerMinor;
        u_int16_t updaterMajor;
        u_int16_t updaterMinor;
        u_int16_t writerMajor;
        u_int16_t writerMinor;
        u_int32_t extensibility;
        u_int32_t cbLicense;
    } transformVersion;
    
    readRange.location += paddedLength;
    readRange.length    = sizeof( transformVersion );
    [[cfbStream read:readRange] getBytes:&transformVersion length:readRange.length];
    
    // Now the license should appear next in a UTF-8-LP-P4 structure (we already read the length)
    readRange.location += readRange.length;
    readRange.length    = transformVersion.cbLicense;
    _license = [cfbStream read:readRange];
    
    return YES;
}


@end
