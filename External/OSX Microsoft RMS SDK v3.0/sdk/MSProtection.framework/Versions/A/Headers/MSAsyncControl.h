/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSAsyncControl.h
 *
 */

#import <Foundation/Foundation.h>

/*!
 
 @class
 @see documentation at - TODO
 This class is used to cancel async SDK operations, it closing all the opened UI.
 
 */
@interface MSAsyncControl : NSObject

- (void)cancel;

@end
