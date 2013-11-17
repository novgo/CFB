//------------------------------------------------------------------------------
// Microsoft Azure Active Directory
//
// Copyright:   Copyright (c) Microsoft Corporation
// Notice:      Microsoft Confidential. For internal use only.
//------------------------------------------------------------------------------

@protocol IPAuthorizationCache;

@interface IPAuthenticationSettings : NSObject

+ (IPAuthenticationSettings *)sharedInstance;

@property (nonatomic) BOOL enableTokenCaching; // Default = YES
@property (nonatomic) BOOL enableSSO;          // Default = YES

@property (strong, nonatomic) NSString *clientId;      // Default = Bundle Identifier
@property (strong, nonatomic) NSString *redirectUri;   // Default = <bundle_identifier>://authorize
@property (strong, nonatomic) NSString *platformId;    // Default = nil

#if TARGET_OS_IPHONE
// Resource Path is only use on iPhone/iPad
@property (strong, nonatomic) NSString *resourcePath;  // Default = nil
#endif

@property (strong, nonatomic) id<IPAuthorizationCache> authorizationCache;

@end
