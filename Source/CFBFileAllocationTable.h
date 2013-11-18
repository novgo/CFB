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

@class CFBFile;

@interface CFBFileAllocationTable : NSObject

- (id)init:(CFBFile __weak *)header error:(NSError * __autoreleasing *)error;

- (u_int32_t)nextSectorInChain:(u_int32_t)index;
- (u_int32_t)sectorsInChain:(u_int32_t)startIndex;


@end
