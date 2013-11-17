//
//  FileProtectionMode.h
//
//  Copyright (C) 2013 Microsoft. All rights reserved.
//
//  Abstract: This class if used for defining the various file protection modes available,
//  and their respective file extension.

#import <Foundation/Foundation.h>

/*!
 @class
 
 @abstract
 Represents the protection mode for the document.
 
 */
@interface FileProtectionMode : NSObject

/*!
 @method
 @abstract
 No protection
 
 */
+ (FileProtectionMode *)none;

/*!
 @method
 @abstract
 Protected using the Pfile format
 
 */
+ (FileProtectionMode *)pfile;

/*!
 @method
 @abstract
 Protected using a custom file format
 
 */
+ (FileProtectionMode *)irm;

/*!
 @method
 @abstract
 Protected using a custom file format, using a deprecated encryption algorithm
 
 */
+ (FileProtectionMode *)irmDeprecated;

/*!
 @method
 @abstract
 Undefined protection mode 
 
 @discussion
 This protection mode means that the document is pending protection, and will become protected once
 it is saved to disk.
 
 */
+ (FileProtectionMode *)undefined;

/*!
 @method
 @abstract
 Gets the file extension used with the protection mode.
 
 */
- (NSString *)fileExtension;

/*!
 @method
 @abstract
 Gets the title display text for the protection mode.
 
 @discussion
 This property is used when updating the application window's title bar.
 
 */
- (NSString *)titleDisplayText;

@end
