//
//  MSCFBSource.m
//  MSCFB-OSX
//
//  Created by Hervey Wilson on 5/14/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBSource.h"

@implementation MSCFBDataSource
{
    NSData       *_data;
}

- (id)initWithData:(NSData *)data
{
    self = [super init];
    
    if ( self )
    {
        _data = data;
    }
    
    return self;
}

- (u_int64_t)length
{
    return [_data length];
}

- (void)getBytes:(void *)bytes range:(NSRange)range
{
    [_data getBytes:bytes range:range];
}

- (NSData *)readRange:(NSRange)range
{
    // TODO: Parameter validation
    return [[NSData alloc] initWithBytesNoCopy:( [_data bytes] + range.location ) length:range.length freeWhenDone:NO];
}

@end

@implementation MSCFBFileSource
{
    NSFileHandle *_handle;
}

- (id)initWithFileHandle:(NSFileHandle *)handle
{
    self = [super init];
    
    if ( self )
    {
        _handle = handle;
    }
    
    return self;
}

- (u_int64_t)length
{
    return [_handle seekToEndOfFile];
}

- (void)getBytes:(void *)bytes range:(NSRange)range
{
    // TODO: Parameter validation
    [_handle seekToFileOffset:range.location];
    
    NSData *result = [_handle readDataOfLength:range.length];
    
    [result getBytes:bytes range:NSMakeRange( 0, range.length )];
}

- (NSData *)readRange:(NSRange)range
{
    // TODO: Parameter validation
    [_handle seekToFileOffset:range.location];
    
    return [_handle readDataOfLength:range.length];
}

@end
