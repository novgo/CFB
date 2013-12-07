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

#import "CFBSource.h"

#import "CFBFile.h"
#import "CFBFileInternal.h"

#import "CFBObject.h"
#import "CFBStorage.h"
#import "CFBStream.h"

#import "CFBProtectedFile.h"

#pragma mark - Implementation constants

static const unichar _DRMContent[]       = { '\x9', 'D', 'R', 'M', 'C', 'o', 'n', 't', 'e', 'n', 't' };
static const unichar _DRMDataSpace[]     = { '\x9', 'D', 'R', 'M', 'D', 'a', 't', 'a', 'S', 'p', 'a', 'c', 'e' };
static const unichar _DRMTransform[]     = { '\x9', 'D', 'R', 'M', 'T', 'r', 'a', 'n', 's', 'f', 'o', 'r', 'm' };
static const unichar _DataSpaces[]       = { '\x6', 'D', 'a', 't', 'a', 'S', 'p', 'a', 'c', 'e', 's' };
static const unichar _EncryptedPackage[] = { 'E', 'n', 'c', 'r', 'y', 'p', 't', 'e', 'd', 'P', 'a', 'c', 'k', 'a', 'g', 'e' };
static const unichar _Primary[]          = { '\x6', 'P', 'r', 'i', 'm', 'a', 'r', 'y' };

@interface CFBProtectedFile ()
@end

@implementation CFBProtectedFile

#pragma mark - Class Methods

+ (CFBProtectedFile *)protectedFileForReadingAtPath:(NSString *)path
{
    NSFileHandle     *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    CFBProtectedFile *file       = nil;
    
    if ( fileHandle )
        file = [[CFBProtectedFile alloc] initWithSource:[[CFBFileSource alloc] initWithFileHandle:fileHandle] error:nil];
    
    return file;
}

+ (CFBProtectedFile *)protectedFileForReadingWithData:(NSData *)data
{
    CFBProtectedFile *file = [[CFBProtectedFile alloc] initWithSource:[[CFBDataSource alloc] initWithData:data] error:nil];
    
    return file;
}

#pragma mark - Initialization

- (id)initWithSource:(id<CFBSource>)source error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    _encryptedContent          = nil;
    _encryptedContentLength    = 0;
    _encryptedProtectionPolicy = nil;
    
    if ( ( self = [super initWithSource:source error:error] ) != nil )
    {
        self = [self validate:error] ? self : nil;
    }
    
    return self;
}

#pragma mark - Public Properties

@synthesize encryptedContent          = _encryptedContent;
@synthesize encryptedContentLength    = _encryptedContentLength;
@synthesize encryptedProtectionPolicy = _encryptedProtectionPolicy;

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
    CFBObject    *cfbObject;
    CFBStorage   *cfbStorage;
    CFBStream    *cfbStream;
    
    // ECMA content has an EncryptedPackage stream; otherwise a DRMContent stream
    cfbObject = [self objectForKey:EncryptedPackage];
    
    if ( cfbObject != nil )
    {
        // ECMA Content
        if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStream class]], @"EncryptedPackage object is not a stream" ) ) return NO;
        
        cfbStream = (CFBStream *)cfbObject;
        
        // The first 8 bytes of the EncryptedPackage stream are the length of the *plaintext* data, not the encrypted data
        u_int64_t contentLength = 0;
        [[cfbStream read:NSMakeRange(0, 8)] getBytes:&contentLength length:8];
        //NSAssert( contentLength == cfbStream.length - 8, @"Incorrect EncryptedPackage length" );
        
        _encryptedContent       = [cfbStream read:NSMakeRange( 8, cfbStream.length - 8 )];
        _encryptedContentLength = contentLength;
    }
    else
    {
        // DRM Content
        cfbObject = [self objectForKey:DRMContent];
        if ( !ASSERT( error, cfbObject != nil, @"Missing DRMContent stream" ) ) return NO;
        if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStream class]], @"DRMContent object is not a stream" ) ) return NO;

        cfbStream = (CFBStream *)cfbObject;
        
        // The first 8 bytes of the DRMContent stream are the length
        u_int64_t contentLength = 0;
        [[cfbStream read:NSMakeRange(0, 8)] getBytes:&contentLength length:8];
        if ( !ASSERT( error, contentLength == cfbStream.length - 8, @"Incorrect DRMContent length" ) ) return NO;
        
        // TODO: What does contentLength mean in this case?
        _encryptedContent       = [cfbStream read:NSMakeRange( 8, cfbStream.length - 8 )];
        _encryptedContentLength = contentLength;
    }
    
    // Back to root: must have a DataSpaces storage
    cfbObject = [self objectForKey:DataSpaces];
    if ( !ASSERT( error, cfbObject != nil, @"Missing DataSpaces storage" ) ) return NO;
    if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStorage class]], @"DataSpace object is not a storage" ) ) return NO;
    
    cfbStorage = (CFBStorage *)cfbObject;
    
    // DataSpaces must have a Version stream
    cfbObject = [cfbStorage objectForKey:Version];
    if ( !ASSERT( error, cfbObject != nil, @"Missing Version stream" ) ) return NO;
    if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStream class]], @"Version object is not a stream" ) ) return NO;
    
    // DataSpaces must have a DataSpaceMap stream
    cfbObject = [cfbStorage objectForKey:DataSpaceMap];
    
    if ( !ASSERT( error, cfbObject != nil, @"Missing DataSpaceMap stream" ) ) return NO;
    if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStream class]], @"DataSpaceMap object is not a stream" ) ) return NO;
    
    // DataSpaces must have a DataSpaceInfo storage
    cfbObject = [cfbStorage objectForKey:DataSpaceInfo];

    if ( !ASSERT( error, cfbObject != nil, @"Missing DataSpaceInfo storage" ) ) return NO;
    if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStorage class]], @"DataSpaceInfo object is not a storage" ) ) return NO;
    
    // DataSpaces must have a TranformInfo storage
    cfbObject = [cfbStorage objectForKey:TransformInfo];
    if ( !ASSERT( error, cfbObject != nil, @"Missing TransformInfo storage" ) ) return NO;
    if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStorage class]], @"TransformInfo object is not a storage" ) ) return NO;
    
    cfbStorage = (CFBStorage *)cfbObject;
    
    // TranformInfo must have a DRMEncryptedTransform storage for ECMA content or a DRMTransform for binary
    if ( [self objectForKey:EncryptedPackage] != nil )
    {
        cfbObject = [cfbStorage objectForKey:DRMEncryptedTransform];
        if ( !ASSERT( error, cfbObject != nil, @"Missing DRMEncryptedTransform storage" ) ) return NO;
        if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStorage class]], @"DRMEncryptedTransform object is not a storage" ) ) return NO;
        
        cfbStorage = (CFBStorage *)cfbObject;
        
        // DRMEncryptedTransform must have a Primary stream
        cfbObject = [cfbStorage objectForKey:Primary];
        if ( !ASSERT( error, cfbObject != nil, @"Missing Primary stream" ) ) return NO;
        if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStream class]], @"Primary object is not a stream" ) ) return NO;
        
        cfbStream = (CFBStream *)cfbObject;
    }
    else
    {
        // TranformInfo must have a DRMTransform storage
        cfbObject = [cfbStorage objectForKey:DRMTransform];
        if ( !ASSERT( error, cfbObject != nil, @"Missing DRMTransform storage" ) ) return NO;
        if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStorage class]], @"DRMTransform object is not a storage" ) ) return NO;
        
        cfbStorage = (CFBStorage *)cfbObject;
        
        // DRMTransform must have a Primary stream
        cfbObject = [cfbStorage objectForKey:Primary];
        if ( !ASSERT( error, cfbObject != nil, @"Missing Primary stream" ) ) return NO;
        if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStream class]], @"Primary object is not a stream" ) ) return NO;
        
        cfbStream = (CFBStream *)cfbObject;
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
    _encryptedProtectionPolicy = [cfbStream read:readRange];
    
    return YES;
}


@end
