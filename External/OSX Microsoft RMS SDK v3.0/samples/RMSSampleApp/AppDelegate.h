//
//  AppDelegate.h
//
//  Copyright (C) 2013 Microsoft. All rights reserved.
//
//  Abstract: The delegate for the application.

#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) MainWindowController *mainWindowController;

@end
