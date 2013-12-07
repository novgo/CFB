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

@implementation CFBStream
{
}

#pragma mark - Public Properties

- (u_int64_t)length
{
    return self.directoryEntry.streamLength;
}

#pragma mark - Public Methods

- (id)init
{
    NSAssert( false, @"Cannot call simple initializer" );
    
    return nil;
}

#pragma mark - Internal Methods

- (id)init:(CFBDirectoryEntry *)entry container:(CFBFile *)container
{
    self = [super init:entry container:container];
    
    if ( self )
    {
    }
    
    return self;
}

@end
