/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSPolicyPicker.h
 *
 */

#import <Foundation/Foundation.h>

@class MSProtectionPolicy;
@class MSPolicyPicker;
@class NSWindow;

/*!
 @protocol
 
 @abstract
 The delegate that is called after the user chooses a protection policy
 
 */
@protocol MSPolicyPickerDelegate <NSObject>

@required

/*!
 @method
 @abstract
 Called after the user selected a protection policy
 */
- (void)didSelectProtection:(MSProtectionPolicy *)protectionPolicy picker:(MSPolicyPicker *)sender;

/*!
 @method
 @abstract
 Called after the user selected the "no protection" option.
 */
- (void)didSelectNoProtection:(MSPolicyPicker *)sender;

@optional

/*!
 @method
 @abstract
 Called if the user cancelled the policy picker
 */
- (void)didCancelProtection:(MSPolicyPicker *)sender;

/*!
 @method
 @abstract
 Called if an error occured in the policy picker
 */
- (void)didFailWithError:(NSError *)error picker:(MSPolicyPicker *)sender;

/*!
 @method
 @abstract
 Called before the policy picker view is loaded.
 */
- (void)willShowPolicyPickerView:(MSPolicyPicker *)sender;

/*!
 @method
 @abstract
 Called right after the policy picker view is closed.
 */
- (void)didDismissPolicyPickerView:(MSPolicyPicker *)sender;

@end

/*!
 @class
 
 @abstract
 Use the MSPolicyPicker to launch the publishing UI for picking a protection policy,
 which can be either based on a template or ad-hoc. 
 The picker hides the acquisition of RMS templates and the creation of the MSProtectionPolicy,
 which occurs based on the user's selection.
 
 */
@interface MSPolicyPicker : NSObject

/*!
 @abstract
 The rights supported by the app.
 */
@property (strong, nonatomic) NSArray/*MSRight*/ *supportedRights;

/*!
 @abstract
 The current policy.
 
 @discussion
 App can set this property before calling pickPolicyAsync to pre-populate the publishing UI.
 When the async operation returned by the pickPolicyAsync completes, this property will be updated with the new policy picked by the user.
 */
@property (strong, nonatomic) MSProtectionPolicy *policy;

/*!
 @method
 @abstract
 Initializes the MSPolicyPicker to have the default supported rights which are MSEditableDocumentRights.all
 
 */
- (id)init;

/*!
 @abstract
 The delegate that is called after the user chooses an option in the policy picker
 */
@property (assign) id<MSPolicyPickerDelegate> delegate;

/*!
 @abstract
 Indicates if the pickProtectionPolicy should send the server the allowAuditedExtraction flag 
 */
@property (nonatomic, readwrite) BOOL allowAuditedExtraction;

/*!
 @method
 @abstract
 Opens the publishing UI and returns the policy picked by the user.
 Receives a parent window in order to display the policy picker as a sheet of that window.
 The method also updates the current policy associated with the picker with the policy picked by the user.
 */
- (void)pickProtectionPolicyModalForWindow:(NSWindow *)parentWindow;

/*!
 @method
 @abstract
 Opens the publishing UI and returns the policy picked by the user.
 This method works without a parent window, and should be used only if there is no window to contain the policy picker.
 The method also updates the current policy associated with the picker with the policy picked by the user.
 */
- (void)pickProtectionPolicy;

/*!
 @method
 @abstract
 Cancels the current policy pick operation.
 */
- (void)cancel;

@end
