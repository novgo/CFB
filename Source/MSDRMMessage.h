//
//  MSDRMMessage.h
//
//  Created by Hervey Wilson on 3/18/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@interface MSDRMMessage : MSDRMDocument

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error;

@end
