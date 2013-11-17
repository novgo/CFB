//------------------------------------------------------------------------------
// Microsoft Azure Active Directory
//
// Copyright:   Copyright (c) Microsoft Corporation
// Notice:      Microsoft Confidential. For internal use only.
//------------------------------------------------------------------------------

@interface IPAuthorization : NSObject <NSCoding>

+ (NSString *)cacheKeyForServer:(NSString *)authorizationServer resource:(NSString *)resource scope:(NSString *)scope;
+ (NSString *)normalizeAuthorizationServer:(NSString *)authorizationServer;

@property (strong, readonly, nonatomic) NSString *authorizationServer;
@property (strong, readonly, nonatomic) NSString *resource;
@property (strong, readonly, nonatomic) NSString *scope;
@property (strong, readonly, nonatomic) NSString *cacheKey;

@property (strong) NSString *accessToken;
@property (strong) NSString *accessTokenType;
@property (strong) NSDate   *expires;
@property (strong) NSString *code;
@property (strong) NSString *refreshToken;

- (id)initWithServer:(NSString *)authorizationServer resource:(NSString *)resource scope:(NSString *)scope;

- (BOOL)isExpired;
- (BOOL)isRefreshable;

@end
