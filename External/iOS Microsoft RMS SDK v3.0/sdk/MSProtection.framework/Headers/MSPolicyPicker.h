/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSPolicyPicker.h
 *
 */

#import <Foundation/Foundation.h>

/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237816(v=vs.85).aspx
 
 */
@class MSProtectionPolicy;

/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237785(v=vs.85).aspx
 
 */
@class MSPolicyPicker;

/*!
 
 @protocol
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237782(v=vs.85).aspx
 
 */
@protocol MSPolicyPickerDelegate <NSObject>

@required

- (void)didSelectProtection:(MSProtectionPolicy *)protectionPolicy picker:(MSPolicyPicker *)sender;

- (void)didSelectNoProtection:(MSPolicyPicker *)sender;

@optional

- (void)didCancelProtection:(MSPolicyPicker *)sender;

- (void)didFailWithError:(NSError *)error picker:(MSPolicyPicker *)sender;

- (void)willShowPolicyPickerView:(MSPolicyPicker *)sender;

- (void)didDismissPolicyPickerView:(MSPolicyPicker *)sender;

@end

/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237785(v=vs.85).aspx
 
 */
@interface MSPolicyPicker : NSObject

@property (strong, nonatomic) NSArray/*MSRight*/ *supportedRights;

@property (strong, nonatomic) MSProtectionPolicy *policy;

- (id)init;

@property (assign) id<MSPolicyPickerDelegate> delegate;

@property (nonatomic, readwrite) BOOL allowAuditedExtraction;

- (void)pickProtectionPolicy;

- (void)cancel;

@end
