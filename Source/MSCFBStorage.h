//
//  MSCFBStorage.h
//
//  Created by Hervey Wilson on 3/12/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@class MSCFBObject;
@class MSCFBFile;

@interface MSCFBStorage : MSCFBObject //MSCFBDirectoryEntry

- (id)init:(MSCFBDirectoryEntry *)entry container:(MSCFBFile *)container;

- (void)addObject:(MSCFBObject *)object;
- (NSArray *)allKeys;
- (NSArray *)allValues;
- (MSCFBObject *)objectForKey:(NSString *)key;

@end
