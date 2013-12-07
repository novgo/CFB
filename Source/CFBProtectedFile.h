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

#pragma once

@protocol CFBSource;

/**
 A CFB file that contains protected content.
 */
@interface CFBProtectedFile : CFBFile

/**
 Load a protected file for reading from the specified path.
 
 The file must already exist when using this method.
 
 @param path The path to the compound file that is to be loaded.
 @return A CFBFile instance representing the file.
 */
+ (CFBProtectedFile *)protectedFileForReadingAtPath:(NSString *)path;

/**
 Load a protected file for reading from the specified NSData object.
 
 @param data The data for the compound file that is to be loaded.
 @return A CFBFile instance representing the file.
 */
+ (CFBProtectedFile *)protectedFileForReadingWithData:(NSData *)data;

@property (readonly, nonatomic) NSData   *encryptedContent;
@property (readonly, nonatomic) u_int64_t encryptedContentLength;
@property (readonly, nonatomic) NSData   *encryptedProtectionPolicy;

/**
 init is not available, use a class method to create an instance
 */
- (id)init __attribute__( ( unavailable("init not available") ) );

- (id)initWithSource:(id<CFBSource>)source error:(NSError *__autoreleasing *)error;
- (BOOL)validate:(NSError *__autoreleasing *)error;

@end
