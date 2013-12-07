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

@class CFBObject;

/**
 A Compound File Binary object.
*/
@interface CFBFile : NSObject

/**
 Load a compound file for reading from the specified path.
 
 The file must already exist when using this method.
 
 @param path The path to the compound file that is to be loaded.
 @return A CFBFile instance representing the file.
*/
+ (CFBFile *)compoundFileForReadingAtPath:(NSString *)path;
    
/**
 Load a compound file for reading from the specified NSData object.
 
 @param data The data for the compound file that is to be loaded.
 @return A CFBFile instance representing the file.
*/
+ (CFBFile *)compoundFileForReadingWithData:(NSData *)data;

/**
 Load a compound file for updating from the specified path.
 
 The file must already exist when using this method.
 
 @param path The path to the compound file that is to be loaded.
 @return A CFBFile instance representing the file.
 @warning Not implemented in this version.
 */
+ (CFBFile *)compoundFileForUpdatingAtPath:(NSString *)path;
    
/**
 Load a compound file for writing from the specified path.
 
 If the file already exists, it is truncated and an empty CFB file is created in its place.
 
 @param path The path to the compound file that is to be loaded.
 @return A CFBFile instance representing the file.
 @warning Not implemented in this version.
 */
+ (CFBFile *)compoundFileForWritingAtPath:(NSString *)path;

/**
 Closes the CFB file.
 */
- (void)close;

/**
 Tests whether the CFB file can be updated.
 */
- (BOOL)isReadOnly;

/**
 The names of the CFBStorage and CFBStream objects stored within the Root storage
 of the CFBFile.
 
 @return An array of strings containing the names of the top level storages and streams.
 */
- (NSArray *)allKeys;
    
/**
 The CFBStorage and CFBStream objects stored within the Root storage
 of the CFBFile.
 
 @return An array of CFBObject (either CFBStorage or CFBStream) within the Root storage of the CFBFile.
 */
- (NSArray *)allValues;
    
/**
 Retrieves the CFBObject (either CFBStorage or CFBStream) within the Root storage with the specified name.
 
 @param key The name of the object to retrieve.
 @return A CFBStorage or CFBStream with the specified name, or nil if the name does not exist.
 */
- (CFBObject *)objectForKey:(NSString *)key;

@end
