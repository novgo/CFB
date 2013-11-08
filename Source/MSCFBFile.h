//
//  MSCompoundFile.h
//
//  Created by Hervey Wilson on 3/6/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#pragma once

@class MSCFBObject;

@interface MSCFBFile : NSObject

+ (MSCFBFile *)compoundFileForReadingAtPath:(NSString *)path;
+ (MSCFBFile *)compoundFileForReadingWithData:(NSData *)data;

+ (MSCFBFile *)compoundFileForUpdatingAtPath:(NSString *)path;
+ (MSCFBFile *)compoundFileForWritingAtPath:(NSString *)path;

- (void)close;

- (NSArray *)allKeys;
- (NSArray *)allValues;
- (MSCFBObject *)objectForKey:(NSString *)key;

@end
