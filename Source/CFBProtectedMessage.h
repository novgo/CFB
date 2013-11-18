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

@class CFBProtectedMessageContent;

@interface CFBProtectedMessage : CFBProtectedFile

// protectedData is only valid after getProtectedMessage
@property (readonly, nonatomic) MSCustomProtectedData *protectedData;
// protectedMessage is only valid after getProtectedMessage
@property (readonly, nonatomic) CFBProtectedMessageContent   *protectedMessage;
// protectionPolicy is only valid after getProtectionPolicy or getProtectedMessage
@property (readonly, nonatomic) MSProtectionPolicy    *protectionPolicy;

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error;

- (void)getProtectedMessage:( void (^)( CFBProtectedMessage *, NSError * ) )completionBlock;
- (void)getProtectionPolicy:( void (^)( CFBProtectedMessage *, NSError *) )completionBlock;

@end
