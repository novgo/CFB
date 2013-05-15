//
//  MSCFBError.m
//  MSCFB-OSX
//
//  Created by Hervey Wilson on 5/14/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBError.h"

NSString * const MSCFBErrorDomain = @"MSCFB";

const int MSCFBBadHeader = 1;

void setError( NSError * __autoreleasing *error, NSString *domain, int code, NSDictionary *userInfo )
{
    if ( error )
    {
        *error = [NSError errorWithDomain:domain code:code userInfo:userInfo];
    }
}