/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSPolicyViewerViewController.h
 *
 */	

#import <Cocoa/Cocoa.h>

@class MSProtectionPolicy;
/*!
 @class
 
 @abstract
 A view controller that generates a view with the RMS policy and user restrictions that are enforced on the given file.
 The view displays all of the supported rights for the app that it runs in and marks which rights are enabled and which are disabled for the specific user and file.
 
 */

@interface MSPolicyViewerViewController : NSViewController

/*!
 @method
 @abstract
 Initializes a new policy viewer view controller with the specified RMS policy and user rights.
 Returns MSPolicyViewerViewController - the new view controller.
 
 @param protectionPolicy      The RMS protection policy for the file. Initializes the policy property.
 
 @param supportedAppRights    An array of MSRight that contains the user rights supported by the app. Initializes the supportedRights property.
 */
- (id)initWithProtectionPolicy:(MSProtectionPolicy *)protectionPolicy supportedAppRights:(NSArray *)supportedAppRights;

/*!
 @abstract
 Gets an array of MSRight that contains the user rights supported by the app.
 */
@property (strong, nonatomic, readonly) NSArray *supportedRights;

/*!
 @abstract
 Gets the RMS protection policy for the file.
 */
@property (strong, nonatomic, readonly) MSProtectionPolicy *policy;

@end
