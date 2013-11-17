//
//  FileProtectionMode.m
//
//  Copyright (C) 2013 Microsoft. All rights reserved.
//
//  Abstract: This class if used for defining the various file protection modes available,
//  and their respective file extension.

#import "FileProtectionMode.h"

@interface FileProtectionMode ()

@property (strong) NSString *fileExtension;
@property (strong) NSString *protectionModeDescription;
@property (strong) NSString *titleDisplayText;

@end

static FileProtectionMode *sNone;
static FileProtectionMode *sPfile;
static FileProtectionMode *sIrm;
static FileProtectionMode *sIrmDeprecated;
static FileProtectionMode *sUndefined;

@implementation FileProtectionMode

+ (void)initialize
{
    if ([self class] == [FileProtectionMode class])
    {
        sNone = [[FileProtectionMode alloc] initWithFileExtension:@"txt" description:@"none" titleDisplayText:@""];
        sPfile = [[FileProtectionMode alloc] initWithFileExtension:@"ptxt" description:@"pfile" titleDisplayText:@"Pfile"];
        sIrm = [[FileProtectionMode alloc] initWithFileExtension:@"txt2" description:@"irm" titleDisplayText:@"IRM"];
        sIrmDeprecated = [[FileProtectionMode alloc] initWithFileExtension:@"txt2" description:@"irmDeprecated" titleDisplayText:@"IRM Deprecated"];
        sUndefined = [[FileProtectionMode alloc] initWithFileExtension:@"undefined" description:@"undefined" titleDisplayText:@"Protected"];
    }
}

- (id)initWithFileExtension:(NSString *)fileExtension
                description:(NSString*)protectionModeDescription
           titleDisplayText:(NSString*)titleDisplayText
{
    if (self = [super init])
    {
        self.fileExtension = fileExtension;
        self.protectionModeDescription = protectionModeDescription;
        self.titleDisplayText = titleDisplayText;
    }
    
    return self;
}

- (NSString*)description
{
    return self.protectionModeDescription;
}

+ (FileProtectionMode *)none
{
    return sNone;
}

+ (FileProtectionMode *)pfile
{
    return sPfile;
}

+ (FileProtectionMode *)irm
{
    return sIrm;
}

+ (FileProtectionMode *)irmDeprecated
{
    return sIrmDeprecated;
}

+ (FileProtectionMode *)undefined
{
    return sUndefined;
}

@end
