//
//  StringEncodingUtils.h
//
//  Copyright (c) 2013 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StringEncodingUtils : NSObject

// Gets the string encoding of the data, based on its BOM
+ (NSStringEncoding)getStringEncoding:(NSData *)data;

@end
