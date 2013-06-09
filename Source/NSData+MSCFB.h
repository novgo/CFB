//
//  NSData+MSCFB.h
//  MSCFB-iOS
//
//  Created by Hervey Wilson on 6/9/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (MSCFB)

- (Byte)readBYTE:(NSUInteger)location;

- (u_int32_t)readDWORD:(NSUInteger)location;
- (u_int32_t)readDWORD:(NSUInteger)location setLocation:(NSUInteger *)newLocation;

- (NSString *)readLPString:(NSUInteger)location;
- (NSString *)readLPString:(NSUInteger)location setLocation:(NSUInteger *)newLocation;

- (NSString *)readLPUnicodeString:(NSUInteger)location;
- (NSString *)readLPUnicodeString:(NSUInteger)location setLocation:(NSUInteger *)newLocation;

@end
