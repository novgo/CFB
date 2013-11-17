/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSPolicyViewer.h
 *
*/

#import <UIKit/UIKit.h>

/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237816(v=vs.85).aspx
 
 */
@class MSProtectionPolicy;

@class MSPolicyViewer;

/*!
 
 @protocol
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237782(v=vs.85).aspx
 
 */
@protocol MSPolicyPickerDelegate;

@protocol MSPolicyViewerDelegate <NSObject>

@optional

- (void)willShowPolicyViewer;

- (void)didShowPolicyViewer;

- (void)willDismissPolicyViewer;

- (void)didDismissPolicyViewer;

@end

/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237793(v=vs.85).aspx
 
 */
@interface MSPolicyViewer : NSObject

+ (MSPolicyViewer *)policyViewerWithProtectionPolicy:(MSProtectionPolicy *)protectionPolicy supportedAppRights:(NSArray *)supportedAppRights;

@property (assign) id<MSPolicyViewerDelegate> delegate;

@property (assign) id<MSPolicyPickerDelegate> policyPickerDelegate;

@property (assign, nonatomic) BOOL isPolicyEditingEnabled;

@property (strong, nonatomic, readonly) NSArray/*MSRight*/ *supportedRights;

@property (strong, nonatomic, readonly) MSProtectionPolicy *policy;

- (void)show;

- (void)dismiss;

@end
