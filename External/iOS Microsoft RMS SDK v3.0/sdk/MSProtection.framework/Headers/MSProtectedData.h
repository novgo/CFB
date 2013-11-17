/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSProtectedData.h
 *
 */

#import <Foundation/Foundation.h>
@class MSProtectionPolicy;
@class MSAsyncControl;
/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237800(v=vs.85).aspx
 
 */
@interface MSProtectedData : NSObject

@property(strong, readonly) MSProtectionPolicy *protectionPolicy;

@property(strong, readonly) NSString *originalFileExtension;

+ (MSAsyncControl *)protectedDataWithProtectedFile:(NSString *)path
                                   completionBlock:(void(^)(MSProtectedData *data, NSError *error))completionBlock;

- (NSUInteger)length:(NSError **)errorPtr;

- (BOOL)getBytes:(void *)buffer length:(NSUInteger)length error:(NSError **)errorPtr;

- (BOOL)getBytes:(void *)buffer range:(NSRange)range error:(NSError **)errorPtr;

- (NSData *)subdataWithRange:(NSRange)range;

- (NSData *)retrieveData;

@end
