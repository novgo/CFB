//------------------------------------------------------------------------------
// Microsoft Azure Active Directory
//
// Copyright:   Copyright (c) Microsoft Corporation
// Notice:      Microsoft Confidential. For internal use only.
//------------------------------------------------------------------------------

// Note that this enum must parallel WebAuthenticationStatus
enum IPAuthenticationStatus
{
    AuthenticationFailed    = 0,
    AuthenticationSucceeded = 1,
    AuthenticationCancelled = 2,
};

@class IPAccessToken;
@class IPAuthorization;

@interface IPAuthenticationResult : NSObject

@property (readonly) enum IPAuthenticationStatus status;

@property (strong, readonly) IPAuthorization *authorization;
@property (strong, readonly) NSString        *error;
@property (strong, readonly) NSString        *errorDescription;

- (id)initWithAuthorization:(IPAuthorization *)authorization;
- (id)initWithError:(NSString *)error description:(NSString *)errorDescription;
- (id)initWithError:(NSString *)error description:(NSString *)errorDescription status:(int)status;

@end
