//
//  MSCFBSource.h
//
//  Created by Hervey Wilson on 5/14/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MSCFBSource <NSObject>

@property (readonly, nonatomic) u_int64_t length;

- (void)readBytes:(void *)bytes range:(NSRange)range;

// Read a range of bytes from the source.
- (NSData *)readRange:(NSRange)range;
- (void)writeData:(NSData *)data location:(NSUInteger)location;

@end

@interface MSCFBDataSource : NSObject <MSCFBSource>

- (id)initWithData:(NSData *)data;

@end

@interface MSCFBFileSource : NSObject <MSCFBSource>

- (id)initWithFileHandle:(NSFileHandle *)handle;

@end
