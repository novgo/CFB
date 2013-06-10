//
//  MSCFBObject.m
//
//  Created by Hervey Wilson on 3/22/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBTypes.h"

#import "MSCFBDirectoryEntry.h"

#import "MSCFBObject.h"
#import "MSCFBObjectInternal.h"

@implementation MSCFBObject
{
    MSCFBDirectoryEntry *_entry;
}

#pragma mark Public Properties

- (NSString *)name
{
    return _entry.name;
}

- (Byte)objectType
{
    return _entry.objectType;
}

#pragma mark Public Methods

- (id)init
{
    return nil;
}

- (id)init:(MSCFBDirectoryEntry *)entry
{
    self = [super init];
    
    if ( self )
    {
        _entry = entry;
    }
    
    return self;
}

#pragma mark Internal Properties

- (MSCFBDirectoryEntry *)directoryEntry
{
    return _entry;
}

#pragma mark Internal Methods

@end
