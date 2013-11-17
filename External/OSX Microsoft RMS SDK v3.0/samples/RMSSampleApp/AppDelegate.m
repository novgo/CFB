//
//  AppDelegate.m
//
//  Copyright (C) 2013 Microsoft. All rights reserved.
//
//  Abstract: The delegate for the application. It takes care of the application startup and termination, as well
//  as some menu item manipulation according to the permissions of the document.

#import "AppDelegate.h"
#import "MainWindowController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSMenuItem *saveMenuItem;
@property (weak) IBOutlet NSMenuItem *saveAsMenuItem;
@property (nonatomic, weak) IBOutlet NSMenu *mainMenu;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (self.mainWindowController == nil)
    {
        self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
        self.mainWindowController.appDelegate = self;
    
        [self.mainWindowController showWindow:self];
    }
}

#pragma mark Menu actions

// Occurs when the user clicks on the "File -> Protection" menu item
- (IBAction)onProtect:(id)sender
{
    [self.mainWindowController protectWithPreferDeprecatedAlgorithm:NO];
}

// Occurs when the user clicks on the "File -> Protection (Deprecated)" menu item
- (IBAction)onProtectDeprecated:(id)sender
{
    [self.mainWindowController protectWithPreferDeprecatedAlgorithm:YES];
}

// Occurs when the user clicks on the "File -> Save As..." menu item
- (IBAction)onSaveAs:(id)sender
{
    [self.mainWindowController saveDocumentAs];
}

#pragma mark Delegate implementations

// Implementing this method is required when trying to enable/disable menu items and enforce rights.
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    // The main view controller knows the state and can validate the items.
    // We have to implement it here because the framework will ask this class
    // about the selectors it implements (onProtect, onSaveAs, onProtectDeprecated)
    return [self.mainWindowController validateUserInterfaceItem:anItem];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (BOOL)applicationShouldClose:(id)sender
{
    return YES;
}

@end
