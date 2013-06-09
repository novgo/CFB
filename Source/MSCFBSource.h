//
//  MSCFBSource.h
//
//  Created by Hervey Wilson on 5/14/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MSCFBSource <NSObject>

@property (readonly, nonatomic) u_int64_t length;

- (void)getBytes:(void *)bytes range:(NSRange)range;
- (NSData *)readRange:(NSRange)range;

@end

@interface MSCFBDataSource : NSObject <MSCFBSource>

- (id)initWithData:(NSData *)data;

@end

@interface MSCFBFileSource : NSObject <MSCFBSource>

- (id)initWithFileHandle:(NSFileHandle *)handle;

@end
