//
//  MSCFBTests.m
//  MSCFBTests
//
//  Created by Hervey Wilson on 4/7/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFB.h"

#import "MSCFBTests.h"

@implementation MSCFBTests

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

- (void)testDocument1AsFile
{
    NSString     *filePath   = [[NSBundle bundleForClass:[self class]] pathForResource:@"document-1" ofType:@"doc"];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    MSCFBFile *file = [[MSCFBFile alloc] initWithFileHandle:fileHandle error:nil];
    
    STAssertTrue( file != nil, @"Failed to load file" );
}

- (void)testDocument1AsData
{
    NSString     *filePath   = [[NSBundle bundleForClass:[self class]] pathForResource:@"document-1" ofType:@"doc"];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    NSData       *fileData   = [fileHandle readDataToEndOfFile];
    
    MSCFBFile *file = [[MSCFBFile alloc] initWithData:fileData error:nil];
    
    STAssertTrue( file != nil, @"Failed to load file" );
}

- (void)testMessage1AsFile
{
    NSString     *filePath   = [[NSBundle bundleForClass:[self class]] pathForResource:@"message-1" ofType:@"rpmsg"];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    MSDRMMessage *file = [[MSDRMMessage alloc] initWithFileHandle:fileHandle error:nil];
    
    STAssertTrue( file != nil, @"Failed to load file" );
}

- (void)testMessage1AsData
{
    NSString     *filePath   = [[NSBundle bundleForClass:[self class]] pathForResource:@"message-1" ofType:@"rpmsg"];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    NSData       *fileData   = [fileHandle readDataToEndOfFile];
    
    MSDRMMessage *file = [[MSDRMMessage alloc] initWithData:fileData error:nil];
    
    STAssertTrue( file != nil, @"Failed to load file" );
}

@end
