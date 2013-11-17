//
//  MSErrorViewer.h
//
//  Copyright (c) 2013 Microsoft. All rights reserved.
//
//  A simple error viewer that conveys errors to users.

#import <Foundation/Foundation.h>

@interface MSErrorViewer : NSObject

+ (id)sharedInstance;

- (void)showError:(NSError *)error;

@end