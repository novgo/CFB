//
//  MainWindowController.h
//
//  Copyright (C) 2013 Microsoft. All rights reserved.
//
//  Abstract: The controller of the main window. This is where most of the application's logic resides in.

#import <Cocoa/Cocoa.h>
#import <MSProtection/MSProtection.h>
#import "AppDelegate.h"

/*!
 @class
 
 @abstract
 The controller of the main window. This is where most of the application's logic resides in.
 
 */
@interface MainWindowController : NSWindowController <NSTextViewDelegate, MSPolicyPickerDelegate, MSProtectionBarDelegate, NSUserInterfaceValidations>

/*!
 @abstract
 The application delegate
 
 */
@property (weak) AppDelegate* appDelegate;

/*!
 @method
 @abstract
 Protects the current document and shows the protection bar.

 @discussion
 When invoked by a user who is not the owner of the document, this will only present the protection bar.
 */
- (void)protectWithPreferDeprecatedAlgorithm:(BOOL)preferDeprecatedAlgorithm;

/*!
 @method
 @abstract
 Saves the document.
 
 */
- (BOOL)saveDocumentAs;

@end
