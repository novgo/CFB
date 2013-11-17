//------------------------------------------------------------------------------
// Microsoft Azure Active Directory
//
// Copyright:   Copyright (c) Microsoft Corporation
// Notice:      Microsoft Confidential. For internal use only.
//------------------------------------------------------------------------------

@class IPAuthorization;

@protocol IPAuthorizationCache <NSObject>

@required
- (IPAuthorization *)authorizationForKey:(NSString *)key;
- (void)setAuthorization:(IPAuthorization *)authorization forKey:(NSString *)key;
- (void)removeAuthorizationForKey:(NSString *)key;
- (void)removeAllAuthorizations;

@end

@interface IPAuthorizationMemoryCache : NSObject <IPAuthorizationCache>

+ (IPAuthorizationMemoryCache *)sharedInstance;

- (IPAuthorization *)authorizationForKey:(NSString *)key;
- (void)setAuthorization:(IPAuthorization *)authorization forKey:(NSString *)key;
- (void)removeAuthorizationForKey:(NSString *)key;
- (void)removeAllAuthorizations;

@end
