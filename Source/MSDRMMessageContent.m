//
//  MSDRMMessageContent.m
//
//  Created by Hervey Wilson on 6/8/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBError.h"
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
    
    MSCFBStream    *_bodyHTML;
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
        else if ( ![self initialize:error] )
            self = nil;
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
        else if ( ![self initialize:error] )
            self = nil;
    }
    
    return self;
}

#pragma mark - Private Methods

- (BOOL)initialize:(NSError *__autoreleasing *)error
{
    MSCFBObject    *cfbObject;
    
    // We must load the OutlookBodyStreamInfo first before we can process other streams
    cfbObject = [_file objectForKey:@"OutlookBodyStreamInfo"];
    
    if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStream class]], @"OutlookBodyStreamInfo is not a stream" ) )
        return NO;
    
    [self loadOutlookBodyStream:(MSCFBStream *)cfbObject];
    
    for ( NSString *key in [_file allKeys] )
    {
        DebugLog( @"Storage entry: %@", key );
        
        if ( [key isEqualToString:@"Attachment List"] )
        {
            // Try to access the attachment contents stream
            cfbObject = [_file objectForKey:key];
            
            if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStorage class]], @"Attachment List object is not a storage" ) )
                return NO;
            
            [self loadAttachmentList:(MSCFBStorage *)cfbObject];
        }
        else if ( [key isEqualToString:@"BodyPT-HTML"] )
        {
            // Try to access the attachment contents stream
            cfbObject = [_file objectForKey:key];
            
            if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStream class]], @"BodyPT-HTML object is not a stream" ) )
                return NO;
            
            _bodyHTML = (MSCFBStream *)cfbObject;
        }
        else if ( [key isEqualToString:@"BodyRTF"] )
        {
            // Try to access the attachment contents stream
            cfbObject = [_file objectForKey:key];
            
            if ( !ASSERT( error, [cfbObject isKindOfClass:[MSCFBStream class]], @"BodyRTF object is not a stream" ) )
                return NO;
            
            _bodyRTF = (MSCFBStream *)cfbObject;
        }
        
    }
    
    return YES;
}

- (void)loadAttachmentList:(MSCFBStorage *)storage
{
    MSCFBObject *cfbObject = nil;
    MSCFBStream *cfbStream = nil;
    
    // The attachment list must have an Attachment Info stream
    cfbObject = [storage objectForKey:@"Attachment Info"];
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
        
        // The storage names are separated by the | character and there is a trailing |. When split, we get one more entry
        // than the number of attachments and that last entry should be empty
        NSArray *attachmentNames = [pipe componentsSeparatedByString:@"|"];
        NSAssert( _contentType == MessageContentTypeRTF || attachmentNames.count == _attachmentCount + 1, @"Error: number of attachment names != attachment count" );
        
        // TODO: The RTF attachment count is stored elsewhere!
        _attachments = [[NSMutableArray alloc] init];
        
        for ( NSString *name in attachmentNames )
        {
            if ( name.length != 0 )
            {
                cfbObject = [storage objectForKey:name];
                NSAssert( cfbObject != nil, @"Attachment not found!" );
                NSAssert( [cfbObject isKindOfClass:[MSCFBStorage class]], @"Attachment object is not a storage" );
                MSDRMMessageAttachment *attachment = [[MSDRMMessageAttachment alloc] initWithStorage:(MSCFBStorage *)cfbObject];
                
                [_attachments addObject:attachment];
            }
        }
    }
}

- (void)loadOutlookBodyStream:(MSCFBStream *)stream
{
    // The first 2 bytes of the OutlookBodyStreamInfo stream are the content type
    u_int16_t contentType = 0;
    [[stream read:NSMakeRange(0, 2)] getBytes:&contentType length:2];
    _contentType = (enum MessageContentType)contentType;
    NSAssert( _contentType == MessageContentTypeHTML || _contentType == MessageContentTypePlain || _contentType == MessageContentTypeRTF, @"Incorrect content type" );
    
    // The second 4 bytes of the OutlookBodyStreamInfo stream are the code page
    u_int32_t codePage = 0;
    [[stream read:NSMakeRange(2, 4)] getBytes:&codePage length:2];
    _codePage = codePage;
}

@end
