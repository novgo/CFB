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

#import "CFBObject.h"

#import "CFBFile.h"
#import "CFBFileInternal.h"

#import "CFBStream.h"
#import "CFBStorage.h"

#import "CFBProtectedAttachment.h"
#import "CFBProtectedMessageContent.h"

@implementation CFBProtectedMessageContent
{
    CFBFile      *_file;
    NSMutableArray *_attachments;
    
    CFBStream    *_bodyHTML;
}

#pragma mark - Public Properties

- (NSArray *)attachments
{
    return _attachments;
}

#pragma mark - Public Methods

- (id)initWithData:(NSData *)data error:(NSError * __autoreleasing *)error
{
    self = [super init];
    
    if ( self )
    {
        _file = [[CFBFile alloc] initWithSource:[[CFBDataSource alloc] initWithData:data] error:error];
        
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
        _file = [[CFBFile alloc] initWithSource:[[CFBFileSource alloc] initWithFileHandle:fileHandle] error:error];
        
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
    CFBObject    *cfbObject;
    
    // We must load the OutlookBodyStreamInfo first before we can process other streams
    cfbObject = [_file objectForKey:@"OutlookBodyStreamInfo"];
    
    if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStream class]], @"OutlookBodyStreamInfo is not a stream" ) )
        return NO;
    
    [self loadOutlookBodyStream:(CFBStream *)cfbObject];
    
    for ( NSString *key in [_file allKeys] )
    {
        DebugLog( @"Storage entry: %@", key );
        
        if ( [key isEqualToString:@"Attachment List"] )
        {
            // Try to access the attachment contents stream
            cfbObject = [_file objectForKey:key];
            
            if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStorage class]], @"Attachment List object is not a storage" ) )
                return NO;
            
            [self loadAttachmentList:(CFBStorage *)cfbObject];
        }
        else if ( [key isEqualToString:@"BodyPT-HTML"] )
        {
            // Try to access the attachment contents stream
            cfbObject = [_file objectForKey:key];
            
            if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStream class]], @"BodyPT-HTML object is not a stream" ) )
                return NO;
            
            _bodyHTML = (CFBStream *)cfbObject;
        }
        else if ( [key isEqualToString:@"BodyRTF"] )
        {
            // Try to access the attachment contents stream
            cfbObject = [_file objectForKey:key];
            
            if ( !ASSERT( error, [cfbObject isKindOfClass:[CFBStream class]], @"BodyRTF object is not a stream" ) )
                return NO;
            
            _bodyRTF = (CFBStream *)cfbObject;
        }
        
    }
    
    return YES;
}

- (void)loadAttachmentList:(CFBStorage *)storage
{
    CFBObject *cfbObject = nil;
    CFBStream *cfbStream = nil;
    
    // The attachment list must have an Attachment Info stream
    cfbObject = [storage objectForKey:@"Attachment Info"];
    NSAssert( cfbObject != nil, @"Missing Attachment Info stream" );
    NSAssert( [cfbObject isKindOfClass:[CFBStream class]], @"Attachment Info object is not a stream" );
    cfbStream = (CFBStream *)cfbObject;
    
    NSRange   readRange = NSMakeRange( 0 , sizeof( u_int32_t) );
    
    // The number of attachments is the the first 4 bytes iff the content type is not RTF
    u_int32_t attachmentCount = 0;
    [[cfbStream read:readRange] getBytes:&attachmentCount length:readRange.length];
    
    if ( _contentType == MessageContentTypeRTF ) NSAssert( attachmentCount == 0xFFFFFFFF, @"Incorrect attachment count for RTF message" );
    if ( attachmentCount == 0xFFFFFFFF ) NSAssert( _contentType == MessageContentTypeRTF, @"Incorrect content type for non-RTF message" );

    _attachmentCount = attachmentCount;
    _attachments     = nil;
    
    // Big gotcha on the pipe string: this is limited to 255 characters so that if there are more, then the
    // pipe is truncated and is not helpful for loading the attachments to the message. Anything we do with
    // the pipe is really just cross-checking since to be safe we have to load the attachments by searching
    // for them by name.
    u_int8_t pipeLength = 0;
    
    readRange.location += readRange.length;
    readRange.length    = sizeof( u_int8_t );
    
    [[cfbStream read:readRange] getBytes:&pipeLength length:readRange.length];
    
    readRange.location += readRange.length;
    readRange.length    = pipeLength << 1; // pipeLength is in unicode characters
    
    if ( pipeLength < 255 )
    {
        // The storage names are separated by the | character and there is a trailing |. When split, we get one more entry
        // than the number of attachments and that last entry should be empty.
        NSString *pipe  = [[NSString alloc] initWithCharacters:[[cfbStream read:readRange] bytes] length:readRange.length >> 1];
        NSArray  *names = [pipe componentsSeparatedByString:@"|"];
    }
    
    // If the message format is RTF, then after the pipe string we have an attachment count that overrides
    // the one specified at the start of the stream.
    if ( _contentType == MessageContentTypeRTF )
    {
        readRange.location += readRange.length;
        readRange.length    = sizeof( u_int32_t );
        
        [[cfbStream read:readRange] getBytes:&attachmentCount length:readRange.length];
        _attachmentCount = attachmentCount;
    }

    if ( _attachmentCount > 0 )
    {
        // Now we load the attachment for real by examining each of the storages and comparing their
        // name with the marker "MailAttachment".
        _attachments = [[NSMutableArray alloc] init];
        
        for ( NSString *name in [storage allKeys] )
        {
            DebugLog( @"Attachment: %@", name );
            
            if ( [name hasPrefix:@"MailAttachment"] )
            {
                cfbObject = [storage objectForKey:name];
                NSAssert( cfbObject != nil, @"Attachment not found!" );
                NSAssert( [cfbObject isKindOfClass:[CFBStorage class]], @"Attachment object is not a storage" );
                
                CFBProtectedAttachment *attachment = [[CFBProtectedAttachment alloc] initWithStorage:(CFBStorage *)cfbObject];
                
                [_attachments addObject:attachment];
            }
        }
        
        NSAssert( _attachments.count == _attachmentCount, @"Error: number of attachments != attachment count" );
    }
}

- (void)loadOutlookBodyStream:(CFBStream *)stream
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
