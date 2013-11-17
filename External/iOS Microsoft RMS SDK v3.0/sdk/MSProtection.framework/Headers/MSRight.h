/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSRight.h
 *
 */

#import <Foundation/Foundation.h>

/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237823(v=vs.85).aspx
 
 */
@interface MSRight : NSObject

- (id)initWithId:(NSString *)identifier
     resourceKey:(NSString *)resourceKey;

- (id)initWithId:(NSString *)identifier
     resourceKey:(NSString *)resourceKey
           table:(NSString *)tableName;

-(NSString *)displayName;

@property (strong, readonly) NSString *identifier;

@end

@interface MSCommonRights : NSObject

+ (MSRight *)owner;
+ (MSRight *)view;

@end

@interface MSEditableDocumentRights : NSObject

+ (MSRight *)edit;
+ (MSRight *)exportable;
+ (MSRight *)extract;
+ (MSRight *)print;
+ (MSRight *)auditedExtract;
+(NSArray *)all;

@end

@interface MSEmailRights : NSObject

+ (MSRight *)reply;
+ (MSRight *)replyAll;
+ (MSRight *)forward;
+ (MSRight *)extract;
+ (MSRight *)print;
+ (NSArray *)all;

@end
