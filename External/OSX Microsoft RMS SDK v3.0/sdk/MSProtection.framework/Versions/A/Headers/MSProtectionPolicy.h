/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSProtectionPolicy.h
 *
 */

#import <Foundation/Foundation.h>

@class MSRight;
@class MSAppData;

/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237816(v=vs.85).aspx
 
 */
@interface MSProtectionPolicy : NSObject

- (BOOL)accessCheck:(MSRight *)right;

@property(strong, readonly) MSAppData *appData;

@property(strong, readonly) NSString *currentUser;

@property(strong, readonly) NSString *contentId;

@property(strong, readonly) NSString *owner;



@end
