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

#import "CFBTypes.h"

#import "CFBDirectoryEntry.h"
#import "CFBFile.h"
#import "CFBFileInternal.h"

#import "CFBObject.h"
#import "CFBObjectInternal.h"

@implementation CFBObject
{
    CFBDirectoryEntry *_entry;
    CFBFile * __weak   _container;
}

#pragma mark - Public Properties

- (NSString *)name
{
    return _entry.name;
}

- (Byte)objectType
{
    return _entry.objectType;
}

#pragma mark - Public Methods

- (id)init
{
    self = nil;
    
    return self;
}

- (NSData *)read:(NSRange)range
{
    if ( _entry.streamLength == 0 )
        return nil;
    
    if ( _container == nil )
    {
        NSAssert( false, @"Access to MSCFBObject when its container has been deallocated" );
        return nil;
    }
    
    if ( [_entry.name isEqualToString:@"Root Entry"] )
    {
        NSAssert( false, @"Access to Root MSCFBStorage stream is not permitted" );
        return nil;
    }
    else
    {
        if ( _entry.streamLength > _container.miniStreamCutoffSize )
            return [_container readStream:_entry.streamStart range:range];
        else
            return [_container readMiniStream:_entry.streamStart range:range];
    }
}

- (NSData *)readAll
{
    if ( _entry.streamLength == 0 )
        return nil;
    
    return [self read:NSMakeRange(0, _entry.streamLength)];
}


#pragma mark - Internal Properties

- (CFBDirectoryEntry *)directoryEntry
{
    return _entry;
}

#pragma mark - Internal Methods

- (id)init:(CFBDirectoryEntry *)entry container:(CFBFile *)container
{
    self = [super init];
    
    if ( self )
    {
        _entry     = entry;
        _container = container;
    }
    
    return self;
}

@end
