//
//  MSDRMDocument.m
//
//  Created by Hervey Wilson on 4/23/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#include <zlib.h>

#import "MSCFBObject.h"
#import "MSCFBSource.h"
#import "MSCFBStorage.h"
#import "MSCFBStream.h"
#import "MSCFBFile.h"

#import "MSDRMFile.h"
#import "MSDRMDocument.h"

@implementation MSDRMDocument
{
}

#pragma mark - Public Properties

@synthesize protectedData    = _protectedData;
@synthesize protectionPolicy = _protectionPolicy;

#pragma mark - Public Methods

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    self = [super initWithData:data error:error];
    
    if ( self )
    {
    }

    return self;
}

- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error
{
    if ( error )
        *error = nil;
    
    self = [super initWithFileHandle:fileHandle error:error];
    
    if ( self )
    {
    }
    
    return self;
}

- (void)getProtectedData:(void (^)(MSDRMDocument *, NSError *))completionBlock
{
    if ( _protectionPolicy )
    {
        
    }
    else
    {
        [self getProtectionPolicy:^( MSDRMDocument *document, NSError *error ) {
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

- (void)getProtectionPolicy:(void (^)(MSDRMDocument *, NSError *))completionBlock
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

- (void)unprotect:( void (^)( MSDRMDocument *, NSError * ) )completionBlock
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
