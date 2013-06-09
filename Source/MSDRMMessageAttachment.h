//
//  MSDRMMessageAttachment.h
//  RPMessageViewer
//
//  Created by Hervey Wilson on 6/8/13.
//  Copyright (c) 2013 Microsoft Corp. All rights reserved.
//

@interface MSDRMMessageAttachment : NSObject

@property (readonly, nonatomic) NSData   *content;
@property (readonly, nonatomic) NSString *contentID;

- (id)initWithStorage:(MSCFBStorage *)storage;

@end
