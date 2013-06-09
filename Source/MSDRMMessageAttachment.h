//
//  MSDRMMessageAttachment.h
//
//  Created by Hervey Wilson on 6/8/13.
//  Copyright (c) 2013 Hervey Wilson. All rights reserved.
//

@interface MSDRMMessageAttachment : NSObject

@property (readonly, nonatomic) u_int32_t attachMethod;

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
