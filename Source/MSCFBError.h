//
//  MSCFBError.h
//
//  Created by Hervey Wilson on 5/14/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#pragma mark - NSError Constants

extern NSString * const MSCFBErrorDomain;

enum MSCFBErrorCode
{
    MSCFBBadHeader = 1
};


#define ASSERT( error, condition, fmt, ... ) Assert( __PRETTY_FUNCTION__, __LINE__, error, condition, fmt, ##__VA_ARGS__ )

extern BOOL Assert( const char *function, int line, NSError * __autoreleasing *error, bool condition, NSString *fmt, ...);