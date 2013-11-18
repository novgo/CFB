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

enum MessageContentType
{
    MessageContentTypePlain = 1,
    MessageContentTypeHTML  = 2,
    MessageContentTypeRTF   = 3
};

@interface CFBProtectedMessageContent : NSObject

@property (readonly, nonatomic) u_int32_t               codePage;
@property (readonly, nonatomic) enum MessageContentType contentType;
@property (readonly, nonatomic) CFBStream            *bodyHTML;
@property (readonly, nonatomic) CFBStream            *bodyRTF;

@property (readonly, nonatomic) NSUInteger              attachmentCount;
@property (readonly, nonatomic) NSArray                *attachments;

- (id)initWithData:(NSData *)data error:(NSError * __autoreleasing *)error;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError * __autoreleasing *)error;

@end
