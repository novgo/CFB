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

#import "MSCFBTypes.h"

@interface MSCFBDirectoryEntry : NSObject

@property (readwrite, nonatomic) NSString *name;
@property (readwrite, nonatomic) u_int32_t left;
@property (readwrite, nonatomic) u_int32_t right;
@property (readwrite, nonatomic) u_int32_t child;

@property (readwrite, nonatomic) Byte      objectType;

@property (readwrite, nonatomic) u_int32_t streamStart;
@property (readwrite, nonatomic) u_int64_t streamLength;

- (id)init;
- (id)init:(MSCFB_DIRECTORY_ENTRY *)directoryEntry;

- (void)getDirectoryEntry:(MSCFB_DIRECTORY_ENTRY *)directoryEntry;

@end
