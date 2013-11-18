//
// Copyright (c) 2013 Hervey Wilson. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and
// limitations under the License.
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
