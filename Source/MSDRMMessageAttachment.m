//
//  MSDRMMessageAttachment.m
//
//  Created by Hervey Wilson on 6/8/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//
#import "NSData+MSCFB.h"

#import "MSCFBObject.h"
#import "MSCFBStream.h"
#import "MSCFBStorage.h"

#import "MSDRMMessageAttachment.h"

@implementation MSDRMMessageAttachment
{
    MSCFBStream *_content;
    NSString    *_contentID;
}

- (NSData *)content
{
    return [_content readAll];
}

- (NSString *)contentID
{
    return _contentID;
}

- (id)initWithStorage:(MSCFBStorage *)storage
{
    if ( storage == nil )
        return nil;
    
    self = [super init];
    
    MSCFBStream *description = nil;
    
    // Try to access the attachment description stream
    MSCFBObject *cfbObject = [storage objectForKey:@"AttachDesc"];
    NSAssert( cfbObject != nil, @"AttachDesc not found!" );
    NSAssert( [cfbObject isKindOfClass:[MSCFBStream class]], @"AttachDesc object is not a stream" );
    
    if ( cfbObject != nil )
    {
        // Now we have the description of the attachment
        description = (MSCFBStream *)cfbObject;
        
        NSData *descriptionData  = [description readAll];
        NSRange readRange        = NSMakeRange( 0, 0 );
        
        // u_int16_t version must be 0x0203
        u_int16_t version = 0;
        
        readRange.location = 0;
        readRange.length   = sizeof( u_int16_t );
        [descriptionData getBytes:&version length:sizeof( u_int16_t )];
        NSAssert( version == 0x0203, @"Invalid attachment version" );
        readRange.location += readRange.length;
        
        // Read the LPString variants of the names
        _longPathName = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        _pathName     = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        _displayName  = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        _longFileName = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        _fileName     = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        _extension    = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        
        // Creation and Last Modified (dont actually read)
        //u_int64_t time = 0;
        
        readRange.length    = sizeof( u_int64_t );
        readRange.location += readRange.length;
        readRange.location += readRange.length;
        
        readRange.length    = sizeof( u_int32_t );
        [descriptionData getBytes:&_attachMethod range:readRange];
        readRange.location += readRange.length;
        
        // Now all the names again, but this time in unicode
        
        // Content ID
        _contentID = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        
        // Content Location
        _contentLocation = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        
        // Long path name
        NSString *string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        if ( !_longPathName || _longPathName == 0 ) _longPathName = string;

        // path name
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        if ( !_pathName || _pathName == 0 ) _pathName = string;
        
        // display name
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        if ( !_displayName || _displayName == 0 ) _displayName = string;
        
        // long file name
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        if ( !_longFileName || _longFileName == 0 ) _longFileName = string;
        
        // file name
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        if ( !_fileName || _fileName == 0 ) _fileName = string;
        
        // extension
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        if ( !_extension || _extension == 0 ) _extension = string;
    }
    
    // Try to access the attachment contents stream
    cfbObject = [storage objectForKey:@"AttachContents"];
    NSAssert( cfbObject != nil, @"AttachContents not found!" );
    NSAssert( [cfbObject isKindOfClass:[MSCFBStream class]], @"AttachContents object is not a stream" );
    _content = (MSCFBStream *)cfbObject;
    
    return self;
}

- (void)initialize
{
    
}

@end
