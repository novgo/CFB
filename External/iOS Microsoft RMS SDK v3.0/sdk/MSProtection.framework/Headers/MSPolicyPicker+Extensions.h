/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSPolicyPicker+Extensions.h
 *
 */

#import "MSPolicyPicker.h"

/*!

 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237790(v=vs.85).aspx
 
 */
@interface MSPolicyPicker (Extensions)

- (void) setPreferDeprecatedAlgorithms:(BOOL) preferDeprecatedAlgorithms;

- (BOOL) preferDeprecatedAlgorithms;

@end
