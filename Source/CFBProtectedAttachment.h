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

enum MSAttachMethod
{
    afNone            = 0x00000000,
    afByValue         = 0x00000001,
    afByReference     = 0x00000002,
    afByReferenceOnly = 0x00000004,
    afEmbeddedMessage = 0x00000005,
    afStorage         = 0x00000006
};

@interface CFBProtectedAttachment : NSObject

@property (readonly, nonatomic) enum MSAttachMethod attachMethod;

@property (readonly, nonatomic) NSData   *content;
@property (readonly, nonatomic) NSString *contentID;
@property (readonly, nonatomic) NSString *contentLocation;

@property (readonly, nonatomic) NSString *displayName;
@property (readonly, nonatomic) NSString *extension;
@property (readonly, nonatomic) NSString *fileName;
@property (readonly, nonatomic) NSString *longFileName;
@property (readonly, nonatomic) NSString *longPathName;
@property (readonly, nonatomic) NSString *pathName;


- (id)initWithStorage:(CFBStorage *)storage;

@end
