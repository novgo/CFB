//
//  MSDRMMessageAttachment.h
//
//  Created by Hervey Wilson on 6/8/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

enum MSAttachMethod
{
    afNone            = 0x00000000,
    afByValue         = 0x00000001,
    afByReference     = 0x00000002,
    afByReferenceOnly = 0x00000004,
    afEmbeddedMessage = 0x00000005,
    afStorage         = 0x00000006
};

@interface MSDRMMessageAttachment : NSObject

@property (readonly, nonatomic) enum MSAttachMethod attachMethod;

@property (readonly, nonatomic) NSData   *content;
@property (readonly, nonatomic) NSString *contentID;
@property (readonly, nonatomic) NSString *contentLocation;

@property (readonly, nonatomic) NSString *displayName;
@property (readonly, nonatomic) NSString *extension;
@property (readonly, nonatomic) NSString *fileName;
@property (readonly, nonatomic) NSString *longFileName;
@property (readonly, nonatomic) NSString *longPathName;
@property (readonly, nonatomic) NSString *pathName;


- (id)initWithStorage:(MSCFBStorage *)storage;

@end
