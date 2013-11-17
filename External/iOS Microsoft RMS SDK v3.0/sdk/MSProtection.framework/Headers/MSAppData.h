/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSAppData.h
 *
 */

#import <Foundation/Foundation.h>

/*!
 
 @class
 @see documentation at - This class is used for extraction of application specific data in the PL
 
 */
@interface MSAppData : NSObject

@property(strong, readonly) NSDictionary *encryptedData;

@end
