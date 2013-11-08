//
//  MSCFBObject.m
//
//  Created by Hervey Wilson on 3/22/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBTypes.h"

#import "MSCFBDirectoryEntry.h"
#import "MSCFBFile.h"
#import "MSCFBFileInternal.h"

#import "MSCFBObject.h"
#import "MSCFBObjectInternal.h"

@implementation MSCFBObject
{
    MSCFBDirectoryEntry *_entry;
    MSCFBFile * __weak   _container;
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

- (MSCFBDirectoryEntry *)directoryEntry
{
    return _entry;
}

#pragma mark - Internal Methods

- (id)init:(MSCFBDirectoryEntry *)entry container:(MSCFBFile *)container
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
