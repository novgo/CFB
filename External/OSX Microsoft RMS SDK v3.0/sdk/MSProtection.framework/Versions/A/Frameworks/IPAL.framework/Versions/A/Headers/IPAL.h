//------------------------------------------------------------------------------
// Microsoft Azure Active Directory
// 
// Copyright:   Copyright (c) Microsoft Corporation
// Notice:      Microsoft Confidential. For internal use only.
//------------------------------------------------------------------------------

#pragma once

#import <TargetConditionals.h>
#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#else
    #import <WebKit/WebKit.h>
#endif

#import <IPAL/IPAuthorization.h>
#import <IPAL/IPAuthorizationCache.h>
#import <IPAL/IPAuthenticationResult.h>
#import <IPAL/IPAuthenticationSettings.h>
#import <IPAL/IPAuthenticationContext.h>

#import <IPAL/HTTPBearerChallenge.h>
#import <IPAL/HTTPBearerChallengeCache.h>
