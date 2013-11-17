/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSProtectionPolicy+Extensions.h
 *
 */

#import "MSProtectionPolicy.h"

@class MSAsyncControl;

/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237818(v=vs.85).aspx
 
 */
@interface MSProtectionPolicy (Extensions)

- (BOOL)doesUseDeprecatedAlgorithm;

+ (MSAsyncControl *)protectionPolicyWithSerializedLicense:(NSData *)serializedLicense
                                          completionBlock:(void(^)(MSProtectionPolicy *protectionPolicy, NSError *error))completionBlock;

- (NSUInteger)getEncryptedContentLength:(NSUInteger)contentLength;

- (NSData *)serializedPolicy;

@end
