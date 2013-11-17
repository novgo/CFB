//
//  SaveFileFormatController.h
//
//  Copyright (C) 2013 Microsoft. All rights reserved.
//
//  Abstract: The controller of the file format selector view, used when saving a document.

#import <Cocoa/Cocoa.h>
#import "FileProtectionMode.h"

/*!
 @class
 
 @abstract
 The controller of the file format selector view, used when saving a document.

 */
@interface SaveFileFormatController : NSViewController <NSOpenSavePanelDelegate>

/*!
 @abstract
 Indicates whether to show protected file formats.
 */
@property (assign) BOOL showProtectedFormats;

/*!
 @abstract
 Indicates whether to show deprecated file formats.
 */
@property (assign) BOOL showDeprecatedFormats;

/*!
 @method
 @abstract
 The file protection mode which was selected.
 */
- (FileProtectionMode *)selectedFileProtectionMode;

/*!
 @abstract
 The selected file encoding
 */
@property (assign) NSStringEncoding selectedEncoding;

/*!
 @method
 @abstract
 Extracts the file path to save the file to, according to the selected protection mode.
 
 @discussion
 This method is used in order to get the proper file path to save to according to the selected
 format in the combo box. The NSSavePanel itself will always return the path using the first
 allowed file type. This method will replace the file type with the one of the selected protection mode.
 
 @param savePath    The original save path
 */
- (NSString *)extractFilePathAccordingToProtectionMode:(NSURL *)savePath;


@end
