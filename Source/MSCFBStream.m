//
//  MSCFBStream.m
//
//  Created by Hervey Wilson on 3/12/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBTypes.h"

#import "MSCFBDirectoryEntry.h"

#import "MSCFBObject.h"
#import "MSCFBObjectInternal.h"

#import "MSCFBStream.h"

@implementation MSCFBStream
{
}

#pragma mark Public Properties

- (u_int64_t)length
{
    return self.directoryEntry.streamLength;
}

#pragma mark Public Methods

- (id)init:(MSCFBDirectoryEntry *)entry
{
    self = [super init:entry];
    
    if ( self )
    {
    }
    
    return self;
}

- (NSData *)read:(NSRange)range
{
    // TODO: Error cases
    return [self.directoryEntry read:range];
}

- (NSData *)readAll
{
    return [self.directoryEntry readAll];
}

@end
