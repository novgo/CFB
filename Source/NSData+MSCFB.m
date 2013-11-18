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

#import "NSData+MSCFB.h"

@implementation NSData (MSCFB)

- (Byte)readBYTE:(NSUInteger)location
{
    return *(Byte *)([self bytes] + location);
}

- (u_int32_t)readDWORD:(NSUInteger)location
{
    return *(u_int32_t *)([self bytes] + location);
}

- (u_int32_t)readDWORD:(NSUInteger)location setLocation:(NSUInteger *)newLocation
{
    u_int32_t result = [self readDWORD:location];
    
    if ( newLocation ) *newLocation = location + sizeof( u_int32_t );
    
    return result;
}

- (NSString *)readLPString:(NSUInteger)location
{
    Byte length = [self readBYTE:location];
    
    if ( length > 0 )
        return [[NSString alloc] initWithBytes:([self bytes] + location + 1) length:length encoding:NSUTF8StringEncoding];
    else
        return nil;
}

- (NSString *)readLPString:(NSUInteger)location setLocation:(NSUInteger *)newLocation
{
    NSString *result = [self readLPString:location];
    
    if ( newLocation ) *newLocation = location + 1 + result.length;
    
    return result;
}

- (NSString *)readLPUnicodeString:(NSUInteger)location
{
    Byte length = [self readBYTE:location];
    
    if ( length > 0 )
        return [[NSString alloc] initWithCharacters:(unichar *)([self bytes] + location + 1) length:length];
    else
        return nil;
}

- (NSString *)readLPUnicodeString:(NSUInteger)location setLocation:(NSUInteger *)newLocation
{
    NSString *result = [self readLPUnicodeString:location];

    if ( newLocation ) *newLocation = location + 1 + ( result.length << 1 );
    
    return result;
}

@end
