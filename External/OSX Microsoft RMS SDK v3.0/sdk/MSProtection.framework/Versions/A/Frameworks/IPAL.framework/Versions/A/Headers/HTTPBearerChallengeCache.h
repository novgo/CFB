//------------------------------------------------------------------------------
// Microsoft Azure Active Directory
//
// Copyright:   Copyright (c) Microsoft Corporation
// Notice:      Microsoft Confidential. For internal use only.
//------------------------------------------------------------------------------

@class HTTPBearerChallenge;

@interface HTTPBearerChallengeCache : NSObject

+ (HTTPBearerChallengeCache *)sharedInstance;

// Retrieve the cached challenge for the specified URL
- (HTTPBearerChallenge *)challengeForURL:(NSURL *)URL;

// Remove the cached challenge for the specified URL
- (void)removeChallengeForURL:(NSURL *)URL;

// Remove all cached challenges
- (void)removeAllChallenges;

// Cache a challenge for the specified URL
- (void)setChallenge:(HTTPBearerChallenge *)challenge forURL:(NSURL *)URL;

@end
