//
//  SaveFileFormatController.m
//
//  Copyright (C) 2013 Microsoft. All rights reserved.
//  
//  Abstract: The controller of the file format selector view, used when saving a document.

#import "FileProtectionMode.h"
#import "SaveFileFormatController.h"

@interface SaveFileFormatController ()

@property (strong) IBOutlet NSMenuItem *protectedTextFileMenuItem;
@property (strong) IBOutlet NSMenuItem *customProtectedTextFileMenuItem;
@property (strong) IBOutlet NSMenuItem *plainTextMenuItem;
@property (weak) IBOutlet NSMenu *fileFormatMenuItems;
@property (strong) IBOutlet NSMenuItem *customProtectedTextFileDeprecatedMenuItem;
@property (weak) IBOutlet NSPopUpButton *fileFormatsPopupButton;
@property (weak) IBOutlet NSPopUpButton *encodingsPopupButton;

@end

@implementation SaveFileFormatController

- (FileProtectionMode *)selectedFileProtectionMode
{
    return (FileProtectionMode *)self.fileFormatsPopupButton.selectedItem.representedObject;
}

- (void)loadView
{
    [super loadView];
    
    self.plainTextMenuItem.representedObject = [FileProtectionMode none];
    self.protectedTextFileMenuItem.representedObject = [FileProtectionMode pfile];
    self.customProtectedTextFileMenuItem.representedObject = [FileProtectionMode irm];
    self.customProtectedTextFileDeprecatedMenuItem.representedObject = [FileProtectionMode irmDeprecated];
    
    [self.fileFormatMenuItems removeAllItems];
    
    if (self.showProtectedFormats)
    {
        if (self.showDeprecatedFormats)
        {
            [self.fileFormatMenuItems addItem:self.customProtectedTextFileDeprecatedMenuItem];
        }
        else
        {
            [self.fileFormatMenuItems addItem:self.protectedTextFileMenuItem];
            [self.fileFormatMenuItems addItem:self.customProtectedTextFileMenuItem];
        }
    }
    else
    {
        [self.fileFormatMenuItems addItem:self.plainTextMenuItem];
    }
    
    [self populateEncodingsMenu];
}

// This method is used in order to get the proper file path to save to according to the selected
// format in the combo box. The NSSavePanel itself will always return the path using the first
// allowed file type. This method will replace the file type with the one of the selected protection mode.
- (NSString*)extractFilePathAccordingToProtectionMode:(NSURL *)savePath
{
    if (savePath == nil)
    {
        NSLog(@"ERROR: savePath should not be nil");
        return nil;
    }
    
    NSString *filePath = [savePath path];
    NSMutableString* returnFilePath = [[NSMutableString alloc] initWithString:filePath];
    NSRange searchRange = [returnFilePath rangeOfString:@"." options:NSBackwardsSearch];
    if (searchRange.length)
    {
        returnFilePath = [[NSMutableString alloc] initWithString:[returnFilePath substringToIndex:searchRange.location]];
        [returnFilePath appendFormat:@".%@", [self.selectedFileProtectionMode fileExtension]];
    }
    
    return returnFilePath;
}

- (void)populateEncodingsMenu
{
    NSMenu *encodingsMenu = self.encodingsPopupButton.menu;
    [encodingsMenu removeAllItems];
    [encodingsMenu addItem:[self createEncodingMenuItem:@"UTF-8" encoding:NSUTF8StringEncoding]];
    [encodingsMenu addItem:[self createEncodingMenuItem:@"UTF-16 Little Endian" encoding:NSUTF16LittleEndianStringEncoding]];
    [encodingsMenu addItem:[self createEncodingMenuItem:@"UTF-16 Big Endian" encoding:NSUTF16BigEndianStringEncoding]];
    [encodingsMenu addItem:[self createEncodingMenuItem:@"UTF-32 Little Endian" encoding:NSUTF32LittleEndianStringEncoding]];
    [encodingsMenu addItem:[self createEncodingMenuItem:@"UTF-32 Big Endian" encoding:NSUTF32BigEndianStringEncoding]];
    
    BOOL setSelectedEncoding = NO;
    for (NSMenuItem *menuItem in encodingsMenu.itemArray)
    {
        if (menuItem.tag == self.selectedEncoding)
        {
            [self setSelectedEncodingMenuItem:menuItem];
            setSelectedEncoding = YES;
            break;
        }
    }
    
    if (!setSelectedEncoding)
    {
        [self setSelectedEncodingMenuItem:(NSMenuItem*)[encodingsMenu.itemArray objectAtIndex:0]];
    }
}

- (void)setSelectedEncodingMenuItem:(NSMenuItem *)sender
{
    [self.encodingsPopupButton selectItem:sender];
    self.selectedEncoding = (NSStringEncoding)self.encodingsPopupButton.selectedItem.tag;
}

- (NSMenuItem *)createEncodingMenuItem:(NSString*)displayName encoding:(NSStringEncoding)encoding
{
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    menuItem.title = displayName;
    menuItem.tag = encoding;
    menuItem.action = @selector(setSelectedEncodingMenuItem:);
    menuItem.target = self;
    
    return menuItem;
}

@end
