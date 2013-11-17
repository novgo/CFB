//
//  MSErrorViewer.m
//
//  Copyright (c) 2013 Microsoft. All rights reserved.
//

#import "MSErrorViewer.h"

@implementation MSErrorViewer

+ (id)sharedInstance
{
    static MSErrorViewer *singleton;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        singleton = [[MSErrorViewer alloc] init];
    });
    
    return singleton;
}

- (void)showError:(NSError *)error
{
    NSAssert([[NSThread currentThread] isMainThread], @"must be called on the main thread!");    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"RMS sample app"
                                                        message:[@"Microsoft Protection SDK v3.0 Error: " stringByAppendingString:error.localizedDescription]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end
