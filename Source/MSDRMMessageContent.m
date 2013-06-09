//
//  MSDRMMessageContent.m
//
//  Created by Hervey Wilson on 6/8/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBObject.h"
#import "MSCFBFile.h"
#import "MSCFBStream.h"
#import "MSCFBStorage.h"

#import "MSDRMMessageAttachment.h"
#import "MSDRMMessageContent.h"

@implementation MSDRMMessageContent
{
    MSCFBFile      *_file;
    NSMutableArray *_attachments;
}

- (NSArray *)attachments
{
    return _attachments;
}

- (id)initWithData:(NSData *)data error:(NSError * __autoreleasing *)error
{
    self = [super init];
    
    if ( self )
    {
        _file = [[MSCFBFile alloc] initWithData:data error:error];
        
        if ( !_file )
            self = nil;
        else
            [self initialize:error];
    }
    
    return self;
}

- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError * __autoreleasing *)error
{
    self = [super init];
    
    if ( self )
    {
        _file = [[MSCFBFile alloc] initWithFileHandle:fileHandle error:error];
        
        if ( !_file )
            self = nil;
        else
            [self initialize:error];
    }
    
    return self;
}

#pragma mark - Private Methods

- (BOOL)initialize:(NSError *__autoreleasing *)error
{
    MSCFBObject    *cfbObject;
    MSCFBStorage   *cfbStorage;
    MSCFBStream    *cfbStream;
    
    // The OutlookBodyStreamInfo contains two values: a WORD with the content type and a DWORD with a codepage
    cfbObject = [_file objectForKey:@"OutlookBodyStreamInfo"];
    NSAssert( cfbObject != nil, @"Missing OutlookBodyStreamInfo stream" );
    NSAssert( [cfbObject isKindOfClass:[MSCFBStream class]], @"OutlookBodyStreamInfo object is not a stream" );
    cfbStream = (MSCFBStream *)cfbObject;
    
    // The first 4 bytes of the OutlookBodyStreamInfo stream are the content type
    
    u_int16_t contentType = 0;
    [[cfbStream read:NSMakeRange(0, 2)] getBytes:&contentType length:2];
    _contentType = (enum MessageContentType)contentType;
    NSAssert( _contentType == MessageContentTypeHTML || _contentType == MessageContentTypePlain || _contentType == MessageContentTypeRTF, @"Incorrect content type" );
    
    // The BodyPT-HTML contains either plain text or HTML content and must be present
    cfbObject = [_file objectForKey:@"BodyPT-HTML"];
    NSAssert( cfbObject != nil, @"Missing BodyPT-HTML stream" );
    NSAssert( [cfbObject isKindOfClass:[MSCFBStream class]], @"BodyPT-HTML object is not a stream" );
    _bodyStream = (MSCFBStream *)cfbObject;
    
    _bodyRTF = nil;
    
    switch ( _contentType )
    {
        case MessageContentTypeHTML:
            break;
            
        case MessageContentTypePlain:
            break;
            
        case MessageContentTypeRTF:
            cfbObject = [_file objectForKey:@"BodyRtf"];
            NSAssert( cfbObject != nil, @"Missing BodyRtf stream" );
            NSAssert( [cfbObject isKindOfClass:[MSCFBStream class]], @"BodyRtf object is not a stream" );
            _bodyRTF = (MSCFBStream *)cfbObject;
            break;
    }
    
    // Look for an attachments list
    cfbObject = [_file objectForKey:@"Attachment List"];
    
    if ( cfbObject )
    {
        // Message has attachments
        NSAssert( [cfbObject isKindOfClass:[MSCFBStorage class]], @"Attachment List object is not a storage" );
        cfbStorage = (MSCFBStorage *)cfbObject;
        
        // The attachment list must have an Attachment Info stream
        cfbObject = [cfbStorage objectForKey:@"Attachment Info"];
        NSAssert( cfbObject != nil, @"Missing Attachment Info stream" );
        NSAssert( [cfbObject isKindOfClass:[MSCFBStream class]], @"Attachment Info object is not a stream" );
        cfbStream = (MSCFBStream *)cfbObject;
        
        NSRange   readRange = NSMakeRange( 0 , sizeof( u_int32_t) );
        
        // The number of attachments is the the first 4 bytes iff the content type is not RTF
        u_int32_t attachmentCount = 0;
        [[cfbStream read:readRange] getBytes:&attachmentCount length:readRange.length];
        readRange.location += readRange.length;
        
        if ( _contentType == MessageContentTypeRTF ) NSAssert( attachmentCount == 0xFFFFFFFF, @"Incorrect attachment count for RTF message" );
        if ( attachmentCount == 0xFFFFFFFF ) NSAssert( _contentType == MessageContentTypeRTF, @"Incorrect content type for non-RTF message" );
        _attachmentCount = attachmentCount;
        _attachments     = nil;
        
        if ( _attachmentCount > 0 )
        {
            u_int8_t pipeLength = 0;
            readRange.length = 1;
            [[cfbStream read:readRange] getBytes:&pipeLength length:readRange.length];
            readRange.location += readRange.length;
            readRange.length    = pipeLength << 1; // pipeLength is in unicode characters

            NSString *pipe = [[NSString alloc] initWithCharacters:[[cfbStream read:readRange] bytes] length:readRange.length >> 1];
            DebugLog( @"Pipe: %@", pipe );
            
            // The storage names are separated by the | character and there is a trailing |. When split, we get one more entry
            // than the number of attachments and that last entry should be empty
            NSArray *attachmentNames = [pipe componentsSeparatedByString:@"|"];
            NSAssert( attachmentNames.count == _attachmentCount + 1, @"Error: number of attachment names != attachment count" );
            
            _attachments = [[NSMutableArray alloc] initWithCapacity:_attachmentCount];
            
            for ( NSString *name in attachmentNames )
            {
                if ( name.length != 0 )
                {
                    DebugLog( @"Attachment %@", name );
                    
                    cfbObject = [cfbStorage objectForKey:name];
                    NSAssert( cfbObject != nil, @"Attachment not found!" );
                    NSAssert( [cfbObject isKindOfClass:[MSCFBStorage class]], @"Attachment object is not a storage" );
                    MSDRMMessageAttachment *attachment = [[MSDRMMessageAttachment alloc] initWithStorage:(MSCFBStorage *)cfbObject];

                    [_attachments addObject:attachment];
                }
            }
        }
    }
    
    return YES;
}

@end
