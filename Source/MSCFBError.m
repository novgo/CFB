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