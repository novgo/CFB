//
//  MSDRMMessage.h
//
//  Created by Hervey Wilson on 3/18/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@class MSDRMMessageContent;

@interface MSDRMMessage : MSDRMFile

// protectedData is only valid after getProtectedMessage
@property (readonly, nonatomic) MSCustomProtectedData *protectedData;
// protectedMessage is only valid after getProtectedMessage
@property (readonly, nonatomic) MSDRMMessageContent   *protectedMessage;
// protectionPolicy is only valid after getProtectionPolicy or getProtectedMessage
@property (readonly, nonatomic) MSProtectionPolicy    *protectionPolicy;

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError *__autoreleasing *)error;

- (void)getProtectedMessage:( void (^)( MSDRMMessage *, NSError * ) )completionBlock;
- (void)getProtectionPolicy:( void (^)( MSDRMMessage *, NSError *) )completionBlock;

@end
