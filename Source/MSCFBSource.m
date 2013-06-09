//
//  MSCFBSource.m
//
//  Created by Hervey Wilson on 5/14/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBSource.h"

@implementation MSCFBDataSource
{
    NSData *_data;
}

#pragma mark - Properties

- (u_int64_t)length
{
    return [_data length];
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

#pragma mark - Data Access

- (void)getBytes:(void *)bytes range:(NSRange)range
{
    if ( !bytes )
        return;
    
    if ( range.location > self.length )
        return;
    
    if ( range.location + range.length > self.length )
        return;
    
    [_data getBytes:bytes range:range];
}

- (NSData *)readRange:(NSRange)range
{
    if ( range.location > self.length )
        return nil;
    
    if ( range.location + range.length > self.length )
        return nil;
    
    return [[NSData alloc] initWithBytesNoCopy:( [_data bytes] + range.location ) length:range.length freeWhenDone:NO];
}

@end

@implementation MSCFBFileSource
{
    NSFileHandle *_handle;
    u_int64_t     _length;
}

#pragma mark - Properties

- (u_int64_t)length
{
    return _length;
}

#pragma mark - Initialization

- (id)initWithFileHandle:(NSFileHandle *)handle
{
    self = [super init];
    
    if ( self )
    {
        _handle = handle;
        _length = [_handle seekToEndOfFile];
    }
    
    return self;
}

#pragma mark - Data Access

- (void)getBytes:(void *)bytes range:(NSRange)range
{
    if ( !bytes )
        return;
    
    if ( range.location > self.length )
        return;
    
    if ( range.location + range.length > self.length )
        return;
    
    [_handle seekToFileOffset:range.location];
    
    NSData *result = [_handle readDataOfLength:range.length];
    
    [result getBytes:bytes range:NSMakeRange( 0, range.length )];
}

- (NSData *)readRange:(NSRange)range
{
    if ( range.location > self.length )
        return nil;
    
    if ( range.location + range.length > self.length )
        return nil;
    
    [_handle seekToFileOffset:range.location];
    
    return [_handle readDataOfLength:range.length];
}

@end
