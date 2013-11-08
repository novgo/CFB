//
//  MSCFBTests.m
//  MSCFBTests
//
//  Created by Hervey Wilson on 4/7/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFB.h"

#import <XCTest/XCTest.h>

@interface Test_MSDRMMessage : XCTestCase
@end

@implementation Test_MSDRMMessage

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testMessages
{
    NSString *filePath = nil;
    
    for ( int i = 1; ; i++ )
    {
        filePath = [[NSBundle bundleForClass:[self class]] pathForResource:[NSString stringWithFormat:@"message-%d", i] ofType:@"rpmsg"];
        
        if ( filePath )
        {
            NSLog( @"%s Testing message-%d.rpmsg", __PRETTY_FUNCTION__, i );
            
            NSError      *error      = nil;
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
            NSData       *fileData   = [fileHandle readDataToEndOfFile];
            MSDRMMessage *file       = nil;
            
            [fileHandle seekToFileOffset:0];
            file = [[MSDRMMessage alloc] initWithFileHandle:fileHandle error:&error];
            
            XCTAssertTrue( file != nil, @"%s Failed to load message-%d as file: %@", __PRETTY_FUNCTION__, i, error.localizedDescription );
            
            file = [[MSDRMMessage alloc] initWithData:fileData error:&error];
            
            XCTAssertTrue( file != nil, @"%s Failed to load message-%d as data: %@", __PRETTY_FUNCTION__, i, error.localizedDescription );
            
        }
        else
        {
            break;
        }
    }
}

@end
