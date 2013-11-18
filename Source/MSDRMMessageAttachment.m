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

#import "MSCFBError.h"

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
    
    _attachMethod = afNone;

    MSCFBObject *cfbObject = nil;
    
    for ( NSString *key in [storage allKeys] )
    {
        if ( [key isEqualToString:@"AttachDesc"] )
        {
            // Attachment Description
            cfbObject = [storage objectForKey:key];
            if ( !ASSERT( nil, [cfbObject isKindOfClass:[MSCFBStream class]], @"AttachDesc is not a stream" ) )
            {
                self = nil;
                return self;
            }
            
            [self loadAttachmentDescription:(MSCFBStream *)cfbObject];
        }
        else if ( [key isEqualToString:@"AttachContents"] )
        {
            // Attachment Content
            cfbObject = [storage objectForKey:key];
            if ( !ASSERT( nil, [cfbObject isKindOfClass:[MSCFBStream class]], @"AttachContents object is not a stream" ) )
            {
                self = nil;
                return self;
            }

            _content = (MSCFBStream *)cfbObject;
        }
        else if ( [key isEqualToString:@"AttachPres"] )
        {
            // Attachment Presentation
            cfbObject = [storage objectForKey:key];
            if ( !ASSERT( nil, [cfbObject isKindOfClass:[MSCFBStream class]], @"AttachPres object is not a stream" ) )
            {
                self = nil;
                return self;
            }
        }
    }
    
    if ( self )
    {
        if ( _attachMethod == afByValue )
        {
        }
        else if ( _attachMethod == afEmbeddedMessage )
        {
            // An embedded message: the content is another msg in the stream.
            // TODO: MS-OXORMMS is confusing here, in tests there is neither an AttachContents or a .msg stream
            //cfbObject = [storage objectForKey:@".msg"];
            //NSAssert( cfbObject != nil, @"AttachContents not found!" );
            //NSAssert( [cfbObject isKindOfClass:[MSCFBStream class]], @"AttachContents object is not a stream" );
            //_content = (MSCFBStream *)cfbObject;
        }
        else
        {
            // We don't support anything else, but MS-OXORMMS says we might see afOle
        }
    }
    
    return self;
}

- (void)loadAttachmentDescription:(MSCFBStream *)description
{
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
    
    // Attachment Method
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

@end
