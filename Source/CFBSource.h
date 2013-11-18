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

#import <Foundation/Foundation.h>

@protocol CFBSource <NSObject>

@property (readonly, nonatomic) u_int64_t length;

- (void)readBytes:(void *)bytes range:(NSRange)range;

// Read a range of bytes from the source.
- (NSData *)readRange:(NSRange)range;
- (void)writeData:(NSData *)data location:(NSUInteger)location;

@end

@interface CFBDataSource : NSObject <CFBSource>

- (id)initWithData:(NSData *)data;

@end

@interface CFBFileSource : NSObject <CFBSource>

- (id)initWithFileHandle:(NSFileHandle *)handle;

@end
