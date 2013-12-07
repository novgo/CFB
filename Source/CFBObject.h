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

@class CFBDirectoryEntry;
@class CFBFile;

enum CFBObjectType
{
    Unknown = 0,
    Storage = 1,
    Stream  = 2,
    Root    = 5
};

/**
 A Compound File Binary object. This is an abstract class, concrete implementations include
 CFBStorage and CFBStream.
 */
@interface CFBObject : NSObject

/**
 The name of the object.
 */
@property (readonly, nonatomic) NSString           *name;

/**
 The type of the object.
 */
@property (readonly, nonatomic) enum CFBObjectType  type;

- (id)init __attribute__( ( unavailable("init not available") ) );

/**
 Reads data from the object using the specified range. Note that objects of type Root
 cannot be read as these contain the mini stream for the CFBFile.
 
 @param range The location and length of data to read.
 @return The data.
 */
- (NSData *)read:(NSRange)range;

/**
 Reads all the data from the object. Note that objects of type Root cannot be read
 as these contain the mini stream for the CFBFile.
 
 @return The data.
 */
- (NSData *)readAll;

@end
