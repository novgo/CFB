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

@class CFBProtectedFile;

/**
 A Microsoft Rights Protected Office Document
 */
@interface CFBProtectedDocument : CFBProtectedFile

/**
 Load a protected document for reading from the specified path.
 
 The file must already exist when using this method.
 
 @param path The path to the compound file that is to be loaded.
 @return A CFBProtectedDocument instance representing the file.
 */
+ (CFBProtectedDocument *)protectedDocumentForReadingAtPath:(NSString *)path;

/**
 Load a protected document for reading from the specified NSData object.
 
 @param data The data for the compound file that is to be loaded.
 @return A CFBProtectedDocument instance representing the file.
 */
+ (CFBProtectedDocument *)protectedDocumentForReadingWithData:(NSData *)data;

/**
 init is not available, use a class method to create an instance
 */
- (id)init __attribute__( ( unavailable("init not available") ) );

/**
 protectedData provides access to the data in the protected document. It is only
 valid after getProtectedData has been called.
 */
@property (readonly, nonatomic) MSCustomProtectedData *protectedData;
/**
 protectionPolicy provides access to the protection policy of the protected document. It is only
 valid after one of getProtectinPolicy or getProtectedData have been called.
 */
@property (readonly, nonatomic) MSProtectionPolicy    *protectionPolicy;

/**
 Extracts the protected data in the document.
 
 This method uses the Microsoft RMS 3.0 SDK to extract the protection policy and may
 require the user to authenticate to complete the operation.
 
 @param completionBlock The block to be called when the protected data has been extracted.
 */
- (void)getProtectedData:( void (^)( CFBProtectedDocument *document, NSError *error ) )completionBlock;

/**
 Extracts the protection policy for the message.
 
 This method uses the Microsoft RMS 3.0 SDK to extract the protection policy and may
 require the user to authenticate to complete the operation.
 
 @param completionBlock The block to be called when the protection policy has been extracted.
 */
- (void)getProtectionPolicy:( void (^)( CFBProtectedDocument *document, NSError *error) )completionBlock;

@end
