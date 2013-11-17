//
//  ExtendedTextView.m
//
//  Copyright (C) 2013 Microsoft. All rights reserved.
//
//  Abstract: Extends the NSTextView class in order to support disabling or enabling printing of the document.

#import "ExtendedTextView.h"

@implementation ExtendedTextView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.canPrint = YES;
    }
    
    return self;
}

// This delegate method is implemented in order to enable or disable the "Print" menu item,
// depending on the value of the canPrint property.
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
    SEL action = [anItem action];
    if (@selector(print:) == action)
    {
        return self.canPrint;
    }
    
    return [super validateUserInterfaceItem:anItem];
}

@end
