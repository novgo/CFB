//
//  MSCFBError.m
//
//  Created by Hervey Wilson on 5/14/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFBError.h"

NSString * const MSCFBErrorDomain = @"MSCFB";

BOOL Assert( const char *function, int line, NSError * __autoreleasing *error, bool condition, NSString *fmt, ...)
{
    if ( !( condition ) )
    {
        va_list args;
        va_start(args, fmt);
        
        // Build message string
        NSString *format      = [@"ERROR: %s[%d][%@] " stringByAppendingString:fmt];
        NSString *description = [NSString stringWithFormat:format, function, line, [[NSThread currentThread] isEqual:[NSThread mainThread]] ? @"main" : @"work", args];
        
        // Always log it
        NSLog( @"%@", description );
        
        // Generate an NSError if supplied
        if ( error )
            *error = [NSError errorWithDomain:MSCFBErrorDomain code:-1 userInfo:[[NSMutableDictionary alloc] initWithObjectsAndKeys:description, NSLocalizedDescriptionKey, nil]];
        
        va_end(args);
        
        return NO;
    }

    return YES;
}