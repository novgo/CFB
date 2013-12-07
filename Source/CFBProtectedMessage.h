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

@class CFBProtectedMessageContent;

/**
 A Microsoft Rights Protected E-mail Message (.rpmsg)
 */
@interface CFBProtectedMessage : CFBProtectedFile

/**
 Load a protected message for reading from the specified path.
 
 The file must already exist when using this method.
 
 @param path The path to the message file that is to be loaded.
 @return A CFBProtectedMessage instance representing the file.
 */
+ (CFBProtectedMessage *)protectedMessageForReadingAtPath:(NSString *)path;

/**
 Load a protected message for reading from the specified NSData object.
 
 @param data The data for the message file that is to be loaded.
 @return A CFBProtectedMessage instance representing the file.
 */
+ (CFBProtectedMessage *)protectedMessageForReadingWithData:(NSData *)data;

/**
 The raw protected data of the message.
 
 This data requires additional processing to extract meaningful content and
 thus is not generally useful. Only valid after getProtectedMessage: has been
 called.
 */
@property (readonly, nonatomic) MSCustomProtectedData      *protectedData;

/**
 The protected message content.
 
 Provides access to the message body and attachments. Only valid after 
 getProtectedMessage: has been called.
 */
@property (readonly, nonatomic) CFBProtectedMessageContent *protectedMessage;

/**
 The protection policy for the message.
 
 Only valid after one of getProtectionPolicy: or getProtectedMessage: has been called.
 */
@property (readonly, nonatomic) MSProtectionPolicy         *protectionPolicy;

/**
 init is not available, use a class method to create an instance
 */
- (id)init __attribute__( ( unavailable("init not available") ) );

/**
 Extracts and decrypts the protected message.
 
 This method uses the Microsoft RMS 3.0 SDK to unprotect the message content and
 may require the user to authenticate to complete the operation.
 
 @param completionBlock The block to be called when the message content has be extracted.
 */
- (void)getProtectedMessage:( void (^)( CFBProtectedMessage *, NSError * ) )completionBlock;

/**
 Extracts the protection policy for the message.
 
 This method uses the Microsoft RMS 3.0 SDK to extract the protection policy and may
 require the user to authenticate to complete the operation.
 
 @param completionBlock The block to be called when the protection policy has been extracted.
 */
- (void)getProtectionPolicy:( void (^)( CFBProtectedMessage *, NSError *) )completionBlock;

@end
