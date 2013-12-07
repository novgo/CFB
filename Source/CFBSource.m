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

#import "CFBSource.h"

@implementation CFBDataSource
{
    NSData *_data;
}

#pragma mark - Initialization

- (id)initWithData:(NSData *)data
{
    self = [super init];
    
    if ( self )
    {
        _data = data;
    }
    
    return self;
}

#pragma mark - Public Properties

- (u_int64_t)length
{
    return [_data length];
}

#pragma mark - Public Methods

- (void)close
{
    // Intentionally empty
}

- (BOOL)isReadOnly
{
    return YES;
}

- (void)readBytes:(void *)bytes range:(NSRange)range
{
    NSParameterAssert( bytes != NULL );
    NSParameterAssert( range.location <= self.length );
    NSParameterAssert( range.location + range.length <= self.length );
    
    if ( !bytes )
        return;
    
    if ( range.location > self.length || range.location + range.length > self.length )
        return;
    
    [_data getBytes:bytes range:range];
}

- (NSData *)readData:(NSRange)range
{
    NSParameterAssert( range.location <= self.length );
    NSParameterAssert( range.location + range.length <= self.length );
    
    if ( range.location > self.length || range.location + range.length > self.length )
        return nil;
    
    NSData *data = [[NSData alloc] initWithBytesNoCopy:( (void *)([_data bytes] + range.location) ) length:range.length freeWhenDone:NO];
    
    NSAssert( data.length == range.length, @"Failed to read correct number of bytes" );
    
    return data;
}

- (void)writeBytes:(void *)bytes range:(NSRange)range
{
#pragma unused( bytes, range )
    @throw [NSException exceptionWithName:@"NotSupported" reason:@"Not Supported" userInfo:nil];
}

- (void)writeData:(NSData *)data location:(NSUInteger)location
{
#pragma unused( data, location )
    @throw [NSException exceptionWithName:@"NotSupported" reason:@"Not Supported" userInfo:nil];
}

@end

@implementation CFBFileSource
{
    
@protected
    NSFileHandle *_handle;
}

#pragma mark - Initialization

- (id)initWithFileHandle:(NSFileHandle *)handle
{
    self = [super init];
    
    if ( self )
    {
        _handle = handle;
    }
    
    return self;
}

- (void)dealloc
{
    [_handle closeFile];
}

#pragma mark - Public Properties

- (u_int64_t)length
{
    return [_handle seekToEndOfFile];
}

#pragma mark - Public Methods

- (void)close
{
    [_handle closeFile];
}

- (BOOL)isReadOnly
{
    return YES;
}

- (void)readBytes:(void *)bytes range:(NSRange)range
{
    NSParameterAssert( bytes != NULL );
    
    if ( !bytes )
        return;
    
    NSData *result = nil;
    
    if ( ( result = [self readData:range] ) != nil )
        [result getBytes:bytes range:NSMakeRange( 0, range.length )];
}

- (NSData *)readData:(NSRange)range
{
    NSParameterAssert( range.location <= self.length );
    NSParameterAssert( range.location + range.length <= self.length );
    
    if ( range.location > self.length || range.location + range.length > self.length )
        return nil;
    
    [_handle seekToFileOffset:range.location];
    
    return [_handle readDataOfLength:range.length];
}

- (void)writeBytes:(void *)bytes range:(NSRange)range
{
#pragma unused( bytes, range )
    @throw [NSException exceptionWithName:@"NotSupported" reason:@"Not Supported" userInfo:nil];
}

- (void)writeData:(NSData *)data location:(NSUInteger)location
{
#pragma unused( data, location )
    @throw [NSException exceptionWithName:@"NotSupported" reason:@"Not Supported" userInfo:nil];
}

@end

@implementation CFBMutableFileSource
{
}

#pragma mark - Public Properties

#pragma mark - Public Methods

- (BOOL)isReadOnly
{
    return NO;
}

- (void)writeBytes:(void *)bytes range:(NSRange)range
{
    NSParameterAssert( bytes != NULL );
    
    [self writeData:[NSData dataWithBytesNoCopy:bytes length:range.length freeWhenDone:NO] location:range.location];
}

- (void)writeData:(NSData *)data location:(NSUInteger)location
{
    NSParameterAssert( data != nil );
    
    [_handle seekToFileOffset:location];
    [_handle writeData:data];
    [_handle synchronizeFile];
}

@end
