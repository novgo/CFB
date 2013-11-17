/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSPolicyEnforcer.h
 *
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237823(v=vs.85).aspx
 
 */
@class MSRight;

/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237816(v=vs.85).aspx
 
 */
@class MSProtectionPolicy;

/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237763(v=vs.85).aspx
 
 */
enum
{
    MSEnforcementActionDisable = 0,
    MSEnforcementActionDisableEdit,
    MSEnforcementActionDisableCopy
};
typedef NSUInteger MSEnforcementAction;

/*!
 
 @class
 @see documentation at http://msdn.microsoft.com/en-us/library/windows/desktop/dn237765(v=vs.85).aspx
 
 */
@interface MSPolicyEnforcer : NSObject

- (id)init;

- (id)initWithProtectionPolicy:(MSProtectionPolicy *)policy;

@property (strong, nonatomic) MSProtectionPolicy *policy;

- (void)addRuleToControl:(NSView *)view whenNoRight:(MSRight *)right doAction:(MSEnforcementAction)action;

- (void)removeAllRulesFromControl:(NSView *)control;

@end
