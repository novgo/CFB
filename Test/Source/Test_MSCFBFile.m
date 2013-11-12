//
//  Test_MSCFBFile.m
//  MSCFB-OSX
//
//  Created by Hervey Wilson on 10/30/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

#import "MSCFB.h"

#import <XCTest/XCTest.h>

@interface Test_MSCFBFile : XCTestCase
@end

@implementation Test_MSCFBFile

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCompoundFileForReadingDoc
{
    NSString *filePath = nil;
    
    for ( int i = 1; ; i++ )
    {
        filePath = [[NSBundle bundleForClass:[self class]] pathForResource:[NSString stringWithFormat:@"document-%d", i] ofType:@"doc"];
        
        if ( filePath )
        {
            NSLog( @"%s Testing document-%d.doc", __PRETTY_FUNCTION__, i );
            
            NSError      *error      = nil;
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
            NSData       *fileData   = [fileHandle readDataToEndOfFile];
            
            [fileHandle closeFile];
            
            MSCFBFile    *file       = nil;
            
            file = [MSCFBFile compoundFileForReadingAtPath:filePath];
            
            XCTAssertTrue( file != nil, @"Failed to load document-%d as file: %@", i, error.localizedDescription );
            
            file = [MSCFBFile compoundFileForReadingWithData:fileData];
            
            XCTAssertTrue( file != nil, @"Failed to load document-%d as data: %@", i, error.localizedDescription );
        }
        else
        {
            break;
        }
    }
}

- (void)testCompoundFileForReadingDocx
{
    NSString *filePath = nil;
    
    for ( int i = 1; ; i++ )
    {
        filePath = [[NSBundle bundleForClass:[self class]] pathForResource:[NSString stringWithFormat:@"document-%d", i] ofType:@"docx"];
        
        if ( filePath )
        {
            NSLog( @"%s Testing document-%d.docx", __PRETTY_FUNCTION__, i );
            
            NSError      *error      = nil;
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
            NSData       *fileData   = [fileHandle readDataToEndOfFile];
            
            [fileHandle closeFile];
            
            MSCFBFile    *file       = nil;
            
            file = [MSCFBFile compoundFileForReadingAtPath:filePath];
            
            XCTAssertTrue( file != nil, @"Failed to load document-%d as file: %@", i, error.localizedDescription );
            
            file = [MSCFBFile compoundFileForReadingWithData:fileData];
            
            XCTAssertTrue( file != nil, @"Failed to load document-%d as data: %@", i, error.localizedDescription );
        }
        else
        {
            break;
        }
    }
}

- (void)testCompoundFileForWriting
{
    NSString  *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"writable.mscfb"];
    MSCFBFile *file    = [MSCFBFile compoundFileForWritingAtPath:tmpPath];
    
    XCTAssertTrue( file, @"Failed to create file" );
    
    [file close];
}

@end
