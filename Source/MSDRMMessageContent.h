//
//  MSDRMMessageContent.h
//  RPMessageViewer
//
//  Created by Hervey Wilson on 6/8/13.
//  Copyright (c) 2013 Microsoft Corp. All rights reserved.
//

enum MessageContentType {
    MessageContentTypePlain = 1,
    MessageContentTypeHTML  = 2,
    MessageContentTypeRTF   = 3
};

@interface MSDRMMessageContent : NSObject

@property (readonly, nonatomic) enum MessageContentType contentType;
@property (readonly, nonatomic) MSCFBStream            *bodyStream;
@property (readonly, nonatomic) MSCFBStream            *bodyRTF;

@property (readonly, nonatomic) NSUInteger              attachmentCount;
@property (readonly, nonatomic) NSArray                *attachments;

- (id)initWithData:(NSData *)data error:(NSError * __autoreleasing *)error;
- (id)initWithFileHandle:(NSFileHandle *)fileHandle error:(NSError * __autoreleasing *)error;

@end
