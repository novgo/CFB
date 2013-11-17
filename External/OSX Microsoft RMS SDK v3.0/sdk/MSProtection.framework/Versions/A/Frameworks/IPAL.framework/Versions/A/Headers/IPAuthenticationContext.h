//------------------------------------------------------------------------------
// Microsoft Azure Active Directory
// 
// Copyright:   Copyright (c) Microsoft Corporation
// Notice:      Microsoft Confidential. For internal use only.
//------------------------------------------------------------------------------

#pragma once

#if TARGET_OS_IPHONE
    typedef UIWebView SysWebView;
#else
    typedef WebView   SysWebView;
#endif

@class IPAuthenticationContext;
@class IPAuthenticationResult;
@class IPAuthenticationSettings;

typedef void (^AuthorizationCallback)(IPAuthenticationResult *) ;

// Interface to the authentication subsystem.
@interface IPAuthenticationContext : NSObject

// Authorization Cache management
+ (IPAuthorization *)authorizationForKey:(NSString *)key;
+ (void)setAuthorization:(IPAuthorization *)authorization forKey:(NSString *)key;
+ (void)removeAuthorizationForKey:(NSString *)key;
+ (void)removeAllAuthorizations;

// OAuth2 Authorization Request using default mechanisms.
// This API must be called from the applications main thread, the delegate is always called on the main thread.
+ (void)requestAuthorization:(NSString *)authorizationServer resource:(NSString *)resource scope:(NSString *)scope completion:( AuthorizationCallback )completionBlock;

// OAuth2 Authorization Request using default mechanisms, using a WebView hosted by the application.
// This API must be called from the applications main thread, the delegate is always called on the main thread.
+ (void)requestAuthorization:(NSString *)authorizationServer resource:(NSString *)resource scope:(NSString *)scope webView:(SysWebView *)webView completion:( AuthorizationCallback )completionBlock;

// This API cancels an outstanding requestAuthorization call.
+ (void)cancelRequestAuthorization;

// Generic OAuth2 Token Request using a Refresh Token
// This API must be called from the applications main thread, the delegate is always called on the main thread.
+ (void)refreshAuthorization:(IPAuthorization *)authorization completion:( AuthorizationCallback )completionBlock;

// Gets the settings for the AuthorizationContext
+ (IPAuthenticationSettings *)settings;

@end
