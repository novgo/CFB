//------------------------------------------------------------------------------
// Microsoft Azure Active Directory
//
// Copyright:   Copyright (c) Microsoft Corporation
// Notice:      Microsoft Confidential. For internal use only.
//------------------------------------------------------------------------------

@interface HTTPBearerChallenge : NSObject

@property (strong, readonly, nonatomic) NSURL    *sourceURL;
@property (strong, readonly, nonatomic) NSString *sourceAuthority;

@property (strong, readonly, nonatomic) NSString *authorizationServer;
@property (strong, readonly, nonatomic) NSString *realm;
@property (strong, readonly, nonatomic) NSString *scope;

// Tests whether a given string represents a Bearer challenge
+ (BOOL)isBearerChallenge:(NSString *)challenge;

// Initialize using a challenge received from a URL
- (id)initWithURL:(NSURL *)URL challenge:(NSString *)challenge;

// Get the value of a specified parameter
- (NSString *)parameterForKey:(NSString *)key;

@end
