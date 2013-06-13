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

- (void)testDoc
{
    NSString *filePath = nil;
    
    for ( int i = 1; ; i++ )
    {
        filePath = [[NSBundle bundleForClass:[self class]] pathForResource:[NSString stringWithFormat:@"document-%d", i] ofType:@"doc"];
    
        if ( filePath )
        {
            NSLog( @"Testing document-%d.doc", i );
            
            NSError      *error      = nil;
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
            NSData       *fileData   = [fileHandle readDataToEndOfFile];
            MSCFBFile    *file       = nil;
            
            file = [[MSCFBFile alloc] initWithFileHandle:fileHandle error:&error];
            
            STAssertTrue( file != nil, @"Failed to load document-%d as file: %@", i, error.localizedDescription );

            file = [[MSCFBFile alloc] initWithData:fileData error:&error];
            
            STAssertTrue( file != nil, @"Failed to load document-%d as data: %@", i, error.localizedDescription );
            
        }
        else
        {
            break;
        }
    }
}

- (void)testDocx
{
    NSString *filePath = nil;
    
    for ( int i = 1; ; i++ )
    {
        filePath = [[NSBundle bundleForClass:[self class]] pathForResource:[NSString stringWithFormat:@"document-%d", i] ofType:@"docx"];
        
        if ( filePath )
        {
            NSLog( @"Testing document-%d.docx", i );
            
            NSError      *error      = nil;
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
            NSData       *fileData   = [fileHandle readDataToEndOfFile];
            MSCFBFile    *file       = nil;
            
            file = [[MSCFBFile alloc] initWithFileHandle:fileHandle error:&error];
            
            STAssertTrue( file != nil, @"Failed to load document-%d as file: %@", i, error.localizedDescription );
            
            file = [[MSCFBFile alloc] initWithData:fileData error:&error];
            
            STAssertTrue( file != nil, @"Failed to load document-%d as data: %@", i, error.localizedDescription );
            
        }
        else
        {
            break;
        }
    }
}

- (void)testMessages
{
    NSString *filePath = nil;
    
    for ( int i = 1; ; i++ )
    {
        filePath = [[NSBundle bundleForClass:[self class]] pathForResource:[NSString stringWithFormat:@"message-%d", i] ofType:@"rpmsg"];
        
        if ( filePath )
        {
            NSLog( @"Testing message-%d.rpmsg", i );
            
            NSError      *error      = nil;
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
            NSData       *fileData   = [fileHandle readDataToEndOfFile];
            MSDRMMessage *file       = nil;
            
            [fileHandle seekToFileOffset:0];
            file = [[MSDRMMessage alloc] initWithFileHandle:fileHandle error:&error];
            
            STAssertTrue( file != nil, @"Failed to load message-%d as file: %@", i, error.localizedDescription );
            
            file = [[MSDRMMessage alloc] initWithData:fileData error:&error];
            
            STAssertTrue( file != nil, @"Failed to load message-%d as data: %@", i, error.localizedDescription );
            
        }
        else
        {
            break;
        }
    }
}

@end
