//
//  PleaseWaitWindowController.m
//
//  Copyright (C) 2013 Microsoft. All rights reserved.
//
//  Abstract: Provides a window controller for presenting a "Please wait..." window, when an operation is in progress.

#import "PleaseWaitWindowController.h"

@interface PleaseWaitWindowController ()

@property (weak) IBOutlet NSProgressIndicator *progressBar;

@end

@implementation PleaseWaitWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"PleaseWaitWindowController"];
    return self;
}

- (void)awakeFromNib
{
    [self.progressBar startAnimation:self];
}

@end
