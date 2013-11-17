/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSSdkErrorCodes.h
 *
 */

#import <Foundation/Foundation.h>

/*!
 
 @enum
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237824(v=vs.85).aspx
 
 */
enum
{
    SDK_ERROR_GENERAL = -1,
    SDK_ERROR_COMMUNICATION = -2,
    SDK_ERROR_DEVICE_REJECTED = -3,
    SDK_ERROR_NO_CONSUMPTION_RIGHTS = -4,
    SDK_ERROR_UNSUPPORTED_SDK_VERSION = -5,
    SDK_ERROR_SERVICE_NOT_AVAILABLE = -6,
    SDK_ERROR_INVALID_PL = -7,
    SDK_ERROR_ONPREM_SERVERS_NOT_SUPPORTED = -8,
    SDK_ERROR_REST_SERVICE_NOT_ENABLED = -9,
    SDK_ERROR_NO_PUBLISHING_RIGHTS = -10,
    SDK_ERROR_PUBLISHING_LICENSE_EXPIRED = -11,
    SDK_ERROR_INVALID_PARAMETER = -1000,
};
typedef NSInteger MSSdkErrorCodes;






