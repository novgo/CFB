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

#import "CFBObject.h"
#import "CFBObjectInternal.h"

#import "CFBStream.h"
#import "CFBStorage.h"

@implementation CFBStorage
{
    NSMutableDictionary *_contents;
}

- (id)init
{
    NSAssert( false, @"Cannot call simple initializer" );
    
    return nil;
}

- (id)init:(CFBDirectoryEntry *)entry container:(CFBFile *)container
{
    self = [super init:entry container:container];
    
    if ( self )
    {
        _contents = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)addObject:(CFBObject *)child
{
    NSAssert( child != nil, @"Child is nil" );

    NSAssert( _contents != nil, @"Contents is nil" );
    [_contents setObject:child forKey:[child name]];
}

- (NSArray *)allKeys
{
    return [_contents allKeys];
}

- (NSArray *)allValues
{
    return [_contents allValues];
}

- (CFBObject *)objectForKey:(NSString *)key
{
    NSAssert( _contents != nil, @"Contents is nil" );

    return [_contents objectForKey:key];
}

@end
