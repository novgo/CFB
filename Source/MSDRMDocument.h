//
//  MSDRMDocument.h
//
//  Created by Hervey Wilson on 4/23/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@interface MSDRMDocument : MSDRMFile

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)outError;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error;

@end
