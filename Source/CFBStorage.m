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

#pragma mark - Public Properties

#pragma mark - Public Methods

- (id)init
{
    NSAssert( false, @"Cannot call simple initializer" );
    
    return nil;
}

- (void)addObject:(CFBObject *)child
{
    NSParameterAssert( child != nil );

    NSAssert( _contents != nil, @"Contents is nil" );
    [_contents setObject:child forKey:[child name]];
}

- (NSArray *)allKeys
{
    NSAssert( _contents != nil, @"Contents is nil" );
    return [_contents allKeys];
}

- (NSArray *)allValues
{
    NSAssert( _contents != nil, @"Contents is nil" );
    return [_contents allValues];
}

- (CFBObject *)objectForKey:(NSString *)key
{
    NSParameterAssert( key != nil );
    
    NSAssert( _contents != nil, @"Contents is nil" );
    return [_contents objectForKey:key];
}

#pragma mark - Internal Methods

- (id)init:(CFBDirectoryEntry *)entry container:(CFBFile *)container
{
    self = [super init:entry container:container];
    
    if ( self )
    {
        _contents = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

@end
