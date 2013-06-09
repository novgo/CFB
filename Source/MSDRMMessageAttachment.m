//
//  MSDRMMessageAttachment.m
//  RPMessageViewer
//
//  Created by Hervey Wilson on 6/8/13.
//  Copyright (c) 2013 Microsoft Corp. All rights reserved.
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
        Byte   *descriptionBytes = [descriptionData bytes];
        NSRange readRange        = NSMakeRange( 0, 0 );
        
        // u_int16_t version must be 0x0203
        u_int16_t version = 0;
        
        readRange.location = 0;
        readRange.length   = sizeof( u_int16_t );
        [descriptionData getBytes:&version length:sizeof( u_int16_t )];
        NSAssert( version == 0x0203, @"Invalid attachment version" );
        readRange.location += readRange.length;
        
        NSString *string;
        
        // Long Path Name
        string = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        
        // Path Name
        string = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        
        // Display Name
        string = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        
        // Long File Name
        string = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        
        // File Name
        string = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        
        // Extension
        string = [descriptionData readLPString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        
        u_int64_t time = 0;
        
        // Creation and Last Modified (dont actually read)
        readRange.length    = sizeof( u_int64_t );
        readRange.location += readRange.length;
        readRange.location += readRange.length;
        
        u_int32_t attachMethod = 0;
        
        readRange.length    = sizeof( u_int32_t );
        [descriptionData getBytes:&attachMethod range:readRange];
        readRange.location += readRange.length;
        
        // Now all the names again, but this time in unicode
        
        // Content ID
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        _contentID = string;
        
        // Content Location
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        
        // Long path name
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );

        // path name
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        
        // display name
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        
        // long file name
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        
        // file name
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
        
        // extension
        string = [descriptionData readLPUnicodeString:readRange.location setLocation:&readRange.location];
        DebugLog( @"%@", string );
    }
    
    // Try to access the attachment description stream
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
