//
//  MSDRMDocument.h
//
//  Created by Hervey Wilson on 4/23/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@interface MSDRMDocument : MSDRMFile

// protectedData is only valid after getContent
@property (readonly, nonatomic) MSCustomProtectedData *protectedData;
// protectionPolicy is only valid after getProtectionPolicy or getContent
@property (readonly, nonatomic) MSProtectionPolicy    *protectionPolicy;


- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)outError;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error;

- (void)getProtectedData:( void (^)( MSDRMDocument *document, NSError *error ) )completionBlock;
- (void)getProtectionPolicy:( void (^)( MSDRMDocument *document, NSError *error) )completionBlock;

@end
