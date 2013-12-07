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

#include <zlib.h>

#import "CFBObject.h"
#import "CFBSource.h"
#import "CFBStorage.h"
#import "CFBStream.h"
#import "CFBFile.h"

#import "CFBProtectedFile.h"
#import "CFBProtectedDocument.h"

@implementation CFBProtectedDocument
{
}

#pragma mark - Class Methods

+ (CFBProtectedDocument *)protectedDocumentForReadingAtPath:(NSString *)path
{
    NSFileHandle         *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    CFBProtectedDocument *file       = nil;
    
    if ( fileHandle )
        file = [[CFBProtectedDocument alloc] initWithSource:[[CFBFileSource alloc] initWithFileHandle:fileHandle] error:nil];
    
    return file;
}

+ (CFBProtectedDocument *)protectedDocumentForReadingWithData:(NSData *)data
{
    CFBProtectedDocument *file = [[CFBProtectedDocument alloc] initWithSource:[[CFBDataSource alloc] initWithData:data] error:nil];
    
    return file;
}

#pragma mark - Public Properties

@synthesize protectedData    = _protectedData;
@synthesize protectionPolicy = _protectionPolicy;

#pragma mark - Public Methods

- (void)getProtectedData:(void (^)(CFBProtectedDocument *, NSError *))completionBlock
{
    if ( _protectionPolicy )
    {
        
    }
    else
    {
        [self getProtectionPolicy:^( CFBProtectedDocument *document, NSError *error ) {
            if ( error )
            {
                completionBlock( document, error );
            }
            else
            {
                // Now try to decrypt the content
                [self unprotect:completionBlock];
            }
        }];
    }
}

- (void)getProtectionPolicy:(void (^)(CFBProtectedDocument *, NSError *))completionBlock
{
    if ( _protectionPolicy )
    {
        completionBlock( self, nil );
    }
    else
    {
        // TODO: The MSProtectionPolicy API expects either a UTF-8 BOM or it assumes the data is UTF16LE.
        const Byte utf8bom[] = { 0xEF, 0xBB, 0xBF };
        NSMutableData *licenseData = [[NSMutableData alloc] initWithCapacity:3 + self.encryptedProtectionPolicy.length];
        [licenseData appendBytes:utf8bom length:3];
        [licenseData appendData:self.encryptedProtectionPolicy];
        
        [MSProtectionPolicy protectionPolicyWithSerializedLicense:licenseData
                                                  completionBlock:^(MSProtectionPolicy *protectionPolicy, NSError *error) {
                                                      
                                                      if ( error )
                                                      {
                                                          completionBlock( self, error );
                                                      }
                                                      else
                                                      {
                                                          self->_protectionPolicy = protectionPolicy;
                                                          
                                                          completionBlock( self, error );
                                                      }
                                                  }];
    }
}


#pragma mark - Private Methods

- (void)unprotect:( void (^)( CFBProtectedDocument *, NSError * ) )completionBlock
{
    // Now try to decrypt the content
    [MSCustomProtectedData customProtectedDataWithPolicy:_protectionPolicy
                                           protectedData:self.encryptedContent
                                    contentStartPosition:0
                                             contentSize:self.encryptedContent.length
                                         completionBlock:^(MSCustomProtectedData *protectedData, NSError *error) {
                                             
                                             if ( error )
                                             {
                                                 completionBlock( self, error );
                                             }
                                             else
                                             {
                                                 self->_protectedData = protectedData;
                                                 
                                                 completionBlock( self, error );
                                             }
                                         }];
}


@end
