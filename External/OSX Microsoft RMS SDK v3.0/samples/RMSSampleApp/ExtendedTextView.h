//
//  ExtendedTextView.h
//
//  Copyright (C) 2013 Microsoft. All rights reserved.
//
//  Abstract: Extends the NSTextView class in order to support enabling or disabling printing of the document.

#import <Cocoa/Cocoa.h>

/*!
 @class
 
 @abstract
 Extends the NSTextView class in order to support enabling or disabling printing of the document.
 
 */
@interface ExtendedTextView : NSTextView <NSUserInterfaceValidations>

/*!
 @abstract
 Indicates whether the document can be printed
 
 */
@property (assign) BOOL canPrint;

@end
