//
//  MSCFBStorage.m
//
//  Created by Hervey Wilson on 3/12/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBTypes.h"

#import "MSCFBDirectoryEntry.h"

#import "MSCFBObject.h"
#import "MSCFBObjectInternal.h"

#import "MSCFBStream.h"
#import "MSCFBStorage.h"

@implementation MSCFBStorage
{
    NSMutableDictionary *_contents;
}

- (id)init
{
    NSAssert( false, @"Cannot call simple initializer" );
    
    return nil;
}

- (id)init:(MSCFBDirectoryEntry *)entry container:(MSCFBFile *)container
{
    self = [super init:entry container:container];
    
    if ( self )
    {
        _contents = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)addObject:(MSCFBObject *)child
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

- (MSCFBObject *)objectForKey:(NSString *)key
{
    NSAssert( _contents != nil, @"Contents is nil" );

    return [_contents objectForKey:key];
}

@end
