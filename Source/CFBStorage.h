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

@class CFBObject;
@class CFBFile;

/**
 A Compound File Binary Storage. A CFBStorage object acts like a file system
 directory object and can contain further CFBStorage and CFBStream objects.
 */
@interface CFBStorage : CFBObject

- (id)init __attribute__( ( unavailable("init not available") ) );

/**
 Adds a CFBObject to the CFBStorage. Only CFBStorage and CFBStream may be
 added to a CFBStorage and on if the CFBStorage is not read only.
 
 @param object The object to be added.
 */
- (void)addObject:(CFBObject *)object;

- (NSArray *)allKeys;
- (NSArray *)allValues;
- (CFBObject *)objectForKey:(NSString *)key;

@end
