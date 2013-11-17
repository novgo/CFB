/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSProtectionBarViewController.h
 *
 */

#import <Cocoa/Cocoa.h>

@class MSProtectionBarViewController;
@class MSProtectionPolicy;

/*!
 @protocol
 
 @abstract
 The delegate that is called when the close button of the protection bar object is tapped.
 
 */
@protocol MSProtectionBarDelegate <NSObject>

- (void)didUserTapCloseButton:(MSProtectionBarViewController *)sender;

@end

/*!
 @class
 
 @abstract
 Represents a protection bar view controller.
 Its view shows a "Protected Content" bar positioned by the developer.
 It should be used following the successful consumption of protected content
 to indicate to the user that the content they are now consuming is protected.
 
 */
@interface MSProtectionBarViewController : NSViewController

/*!
 @method
 @abstract
 Initializes an MSProtectionBarViewController object with the specified protection policy to be displayed
 and the supported app rights. 
 
 @param protectionPolicy      The protection policy to display in the bar.
 
 @param supportedAppRights    The supported app rights to display from the bar.
 */
- (id)initWithProtectionPolicy:(MSProtectionPolicy *)protectionPolicy supportedAppRights:(NSArray *)supportedAppRights;

/*!
 @abstract
 The delegate that is called when the close button of the MSProtectionBar object is tapped.
 */
@property (assign) id<MSProtectionBarDelegate> delegate;

@end
