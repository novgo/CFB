//
//  MainWindowController.m
//
//  Copyright (C) 2013 Microsoft. All rights reserved.
//
//  Abstract: The controller of the main window. This is where most of the application's logic resides in.

#import <MSProtection/MSProtection.h>

// This import is used when working with a custom file format.
#import <MSProtection/MSCustomProtection.h>

// Application specific
#import "MainWindowController.h"
#import "SaveFileFormatController.h"
#import "FileProtectionMode.h"
#import "PleaseWaitWindowController.h"
#import "ExtendedTextView.h"

@interface MainWindowController ()

#pragma mark - Properties

#pragma mark Protection-related properties

// An array of the rights supported by the application
@property (strong) NSArray *supportedAppRights;

// The protection policy of the document
@property (nonatomic, strong) MSProtectionPolicy *protectionPolicy;

// A protection bar to display the policy name and rights of the document
@property (strong) MSProtectionBarViewController *protectionBar;

// An enforcer which applies the policy to views and controls
@property (nonatomic, strong) MSPolicyEnforcer *policyEnforcer;

#pragma mark - Application specific properties

@property (unsafe_unretained) IBOutlet ExtendedTextView *textView;
@property (weak) IBOutlet NSView *protectionBarContainerView;

// The file's initial protection mode. This is changed whenever a file is loaded, saved
// or when a new document is created.
@property (strong) FileProtectionMode *initialFileProtectionMode;

// The file protection mode - whether the file is protected or not and in which format
@property (nonatomic, strong) FileProtectionMode *fileProtectionMode;

// The file path of the currently loaded file. Starts as nil for Untitled.
@property (nonatomic, strong) NSString *filePath;

// Indicates whether the file was modified since opened/last saved or not.
// When the value is YES, it will be indicated in the window title bar as a '*' next to the file name
@property (nonatomic, assign) BOOL wasFileModified;

// Indicates a lengthy operation is taking place
@property (assign, nonatomic) BOOL isInProgress;

// The encoding of the file
@property (assign) NSStringEncoding fileEncoding;

// This controller controls a "Please wait..." sheet which is displayed
// according to the value of the isInProgress property
@property (strong) PleaseWaitWindowController *pleaseWaitController;

@end


@implementation MainWindowController

// Needed when using the deprecated algorithm.
static const NSUInteger kDeprecatedAlgAlignement = 16;

#pragma mark - Initialization

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.textView.delegate = self;
    
    self.supportedAppRights = @[[MSCommonRights view],
                                [MSEditableDocumentRights edit],
                                [MSEditableDocumentRights extract],
                                [MSEditableDocumentRights exportable],
                                [MSEditableDocumentRights print]];

    // We init the policy enforcer though no policy is set to add rules
    self.policyEnforcer = [[MSPolicyEnforcer alloc] init];
    
    // Add enforcement rules - this will apply to any policy we will set to the enforcer
    [self.policyEnforcer addRuleToControl:self.textView
                              whenNoRight:[MSEditableDocumentRights edit]
                                 doAction:MSEnforcementActionDisableEdit];
    [self.policyEnforcer addRuleToControl:self.textView
                              whenNoRight:[MSEditableDocumentRights extract]
                                 doAction:MSEnforcementActionDisableCopy];
    
    self.pleaseWaitController = [[PleaseWaitWindowController alloc] init];

    [self newDocument:self];
}

#pragma mark Public methods

- (void)protectWithPreferDeprecatedAlgorithm:(BOOL)preferDeprecatedAlgorithms
{
    if ([self isOwner])
    {
        self.isInProgress = YES;
        MSProtectionPolicy *policy;
        // In case we switch between deprecated and non-deprecated algorithms, we want to allow the user
        // to select all possible templates, regardless of the current protection policy
        if ((self.protectionPolicy != nil) && (self.protectionPolicy.doesUseDeprecatedAlgorithm != preferDeprecatedAlgorithms))
        {
            policy = nil;
        }
        else
        {
            policy = self.protectionPolicy;
        }

        [self pickProtectionPolicyWithCurrentPolicy:policy preferDeprecatedAlgorithms:preferDeprecatedAlgorithms];
    }
    else
    {
        [self showProtectionBar];
    }
}

- (BOOL)saveDocumentAs
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    SaveFileFormatController *fileFormatController = [[SaveFileFormatController alloc] initWithNibName:@"SaveFileFormatController" bundle:nil];
    [savePanel setCanCreateDirectories:YES];
    
    if (self.protectionPolicy == nil)
    {
        fileFormatController.showProtectedFormats = NO;
        [savePanel setAllowedFileTypes:@[@"txt"]];
    }
    else
    {
        fileFormatController.showProtectedFormats = YES;
        fileFormatController.showDeprecatedFormats = self.protectionPolicy.doesUseDeprecatedAlgorithm;
        [savePanel setAllowedFileTypes:@[@"ptxt", @"txt2"]];
    }
    
    fileFormatController.selectedEncoding = self.fileEncoding;
    // We set the accessory view in order to display the combo box for choosing a file type
    [savePanel setAccessoryView:fileFormatController.view];
    
    // Display the save dialog
    BOOL retVal = NO;
    if ([savePanel runModal] == NSOKButton)
    {
        NSString *savePath = [fileFormatController extractFilePathAccordingToProtectionMode:[savePanel URL]];
        NSLog(@"Got path: %@", savePath);
        FileProtectionMode *selectedFileProtectionMode = [fileFormatController selectedFileProtectionMode];
        NSLog(@"Selected file protection mode: %@", selectedFileProtectionMode);
        NSStringEncoding encoding = fileFormatController.selectedEncoding;
        retVal = [self saveFile:savePath protectionMode:selectedFileProtectionMode encoding:encoding];
    }
  
    return retVal;
}

#pragma mark Property implementation

- (NSString *)fileTitle
{
    if (self.filePath == nil)
    {
        return @"Untitled";
    }
    
    return [self.filePath lastPathComponent];
}

- (void)setIsInProgress:(BOOL)isInProgress
{
    if (_isInProgress != isInProgress)
    {
        _isInProgress = isInProgress;
        if (_isInProgress)
        {
            [[NSApplication sharedApplication] beginSheet:self.pleaseWaitController.window modalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        }
        else
        {
            if (self.pleaseWaitController)
            {
                [self.pleaseWaitController.window orderOut:self];
                [[NSApplication sharedApplication] endSheet:self.pleaseWaitController.window];
            }
        }
    }
}

- (void)setFilePath:(NSString *)filePath
{
    _filePath = filePath;
    [self updateWindowContent];
}

- (void)setFileProtectionMode:(FileProtectionMode *)fileProtectionMode
{
    if (_fileProtectionMode != fileProtectionMode)
    {
        _fileProtectionMode = fileProtectionMode;
        [self updateWindowContent];
    }
}

- (void)setWasFileModified:(BOOL)wasFileModified
{
    if (_wasFileModified != wasFileModified)
    {
        _wasFileModified = wasFileModified;
        [self updateWindowTitle];
    }
}

- (void)setProtectionPolicy:(MSProtectionPolicy *)protectionPolicy
{
    if (_protectionPolicy != protectionPolicy)
    {
        _protectionPolicy = protectionPolicy;
        [self.policyEnforcer setPolicy:self.protectionPolicy];
        
        // The policyEnforcer updates our NSTextView automatically, but we still have to
        // update application menus Such as Save/Save As
        [self updateUIAccordingToChangedPolicy];
    }
}

- (void)updateUIAccordingToChangedPolicy
{
    self.wasFileModified = YES;
    
    // To change menu items which are not text based View/Control specific (Eg. Save which is relevant in all parts of
    // our application and not only for out textView) our application and relevant controls must implement the
    // NSUserInterfaceValidations protocol
    self.textView.canPrint = self.protectionPolicy == nil || [self.protectionPolicy accessCheck:[MSEditableDocumentRights print]];
    [self updateWindowContent];    
}

#pragma mark Event handling

- (void)openDocument:(id)sender
{
    if (![self saveModifiedFile])
    {
        return;
    }

    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    openPanel.canChooseFiles = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.allowedFileTypes = @[@"txt", @"ptxt", @"txt2"];
    
    if (([openPanel runModal] == NSOKButton) && (openPanel.URLs.count > 0))
    {
        NSString *filePath = [[openPanel.URLs objectAtIndex:0] path];
        [self loadFile:filePath];
    }
 }

- (BOOL)save
{
    if (self.filePath == nil || self.initialFileProtectionMode != self.fileProtectionMode)
    {
        return [self saveDocumentAs];
    }
    else
    {
        if (self.wasFileModified)
        {
            return [self saveFile:self.filePath protectionMode:self.fileProtectionMode encoding:self.fileEncoding];
        }
    }
    
    return NO;
}

- (void)saveDocument:(id)sender
{
    [self save];
}

- (void)newDocument:(id)sender
{
    if ([self saveModifiedFile])
    {
        self.initialFileProtectionMode = [FileProtectionMode none];
        self.fileProtectionMode = [FileProtectionMode none];
        self.fileEncoding = NSUTF8StringEncoding;
        self.protectionPolicy = nil;
        self.isInProgress = NO;
        self.wasFileModified = NO;
        self.filePath = nil;
        [self.textView setString:@""];
        self.textView.canPrint = YES;
        [self updateWindowTitle];
    }
}

#pragma mark - Helper methods

- (BOOL)isOwner
{
    return (self.protectionPolicy == nil || [self.protectionPolicy accessCheck:[MSCommonRights owner]]);
}

- (BOOL)saveModifiedFile
{
    if (!self.wasFileModified)
    {
        return YES;
    }
    
    NSAlert *fileModifiedAlert = [[NSAlert alloc] init];
    [fileModifiedAlert.window setTitle:@"RMS sample app"];
    fileModifiedAlert.messageText = [[NSString alloc] initWithFormat:@"Do you want to save the changes you made in the document \"%@\"?", self.fileTitle];
    fileModifiedAlert.informativeText = @"Your changes will be lost if you don't save them.";
    [fileModifiedAlert addButtonWithTitle:@"Save"];
    [fileModifiedAlert addButtonWithTitle:@"Cancel"];
    [fileModifiedAlert addButtonWithTitle:@"Don't Save"];
    
    NSInteger result = [fileModifiedAlert runModal];
    switch (result)
    {
        case NSAlertFirstButtonReturn:
            return [self save];
        case NSAlertSecondButtonReturn:
            return NO;
        default:
            return YES;
    }
        
    return NO;
}

// Handles an error by displaying it inside an alert
- (void)handleError:(NSError *)error
{
    self.isInProgress = NO;
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = error.localizedDescription;
    [alert.window setTitle:@"RMS sample app"];
    [alert runModal];
}


- (BOOL)saveFile:(NSString *)savePath protectionMode:(FileProtectionMode *)selectedFileProtectionMode encoding:(NSStringEncoding)encoding
{
    if (![savePath hasSuffix:[selectedFileProtectionMode fileExtension]])
    {
        NSLog(@"ERROR: Save path does not match selected format. Selected format: %@ | Save path: %@", selectedFileProtectionMode, savePath);
        return NO;
    }
 
    self.isInProgress = YES;
    
    NSData *dataToSave = [[self.textView string] dataUsingEncoding:encoding];
    dataToSave = [self addBomToData:dataToSave encoding:encoding];
    
    // This is the base logic for successful save callbacks. The 2 callbacks defined below are using it.
    void (^onSuccessfulSaveWithProtectionMode)(FileProtectionMode *protectionMode) = ^(FileProtectionMode *protectionMode)
    {
        self.filePath = savePath;
        self.wasFileModified = NO;
        self.fileProtectionMode = protectionMode;
        self.initialFileProtectionMode = protectionMode;
        self.fileEncoding = encoding;
        self.isInProgress = NO;
    };
    
    // This callback is called when the save operation was successful.
    void (^onSuccessfulSave)() = ^()
    {
        onSuccessfulSaveWithProtectionMode(selectedFileProtectionMode);
    };
    
    // This callback is called when the save operation for custom format was successful.
    void (^onSuccessfulCustomSave)() = ^()
    {
        FileProtectionMode *protectionMode = [FileProtectionMode irm];
        if (self.protectionPolicy.doesUseDeprecatedAlgorithm)
        {
            protectionMode = [FileProtectionMode irmDeprecated];
        }
        
        onSuccessfulSaveWithProtectionMode(protectionMode);
    };

    NSError* error = nil;
    if (selectedFileProtectionMode == [FileProtectionMode none] ||
        selectedFileProtectionMode == [FileProtectionMode pfile])
    {
        // This method will save a regular .txt file if the FileProtectionMode is 'none'
        [self saveProtectedTextFile:savePath
                      dataToProtect:dataToSave
                            success:onSuccessfulSave
                              error:&error];
    }
    else if ((selectedFileProtectionMode == [FileProtectionMode irm]) ||
             (selectedFileProtectionMode == [FileProtectionMode irmDeprecated]))
    {
        [self saveCustomProtectedTextFile:savePath
                            dataToProtect:dataToSave
                                  success:onSuccessfulCustomSave
                                    error:&error];
    }
    else
    {
        NSLog(@"ERROR: Unsupported file format was selected: %@", selectedFileProtectionMode);
        self.isInProgress = NO;
        return NO;
    }

    return YES;
}

- (void)loadFile:(NSString *)filePath
{
    self.isInProgress = YES;

    __block FileProtectionMode *fileProtectionMode = nil;
    __block MainWindowController * blockSelf = self;
    void (^onSuccessfulLoadWithProtectionMode)(FileProtectionMode *protectionMode, NSData *unprotectedData) =
    ^(FileProtectionMode *protectionMode, NSData *unprotectedData)
    {
        NSStringEncoding stringEncoding = [blockSelf getStringEncoding:unprotectedData];
        blockSelf.fileEncoding = stringEncoding;
        [blockSelf.textView setString:[[NSString alloc] initWithData:unprotectedData encoding:stringEncoding]];
        
        [blockSelf showProtectionBar];

        blockSelf.wasFileModified = NO;
        blockSelf.filePath = filePath;
        blockSelf.fileProtectionMode = protectionMode;
        blockSelf.initialFileProtectionMode = protectionMode;
        blockSelf.isInProgress = NO;
        blockSelf = nil;
    };
    
    void (^onSuccessfulLoad)(NSData *unprotectedData) = ^(NSData *unprotectedData)
    {
        onSuccessfulLoadWithProtectionMode(fileProtectionMode, unprotectedData);
    };
    
    void (^onSuccessfulCustomLoad)(NSData *unprotectedData) = ^(NSData *unprotectedData)
    {
        if (self.protectionPolicy.doesUseDeprecatedAlgorithm)
        {
            fileProtectionMode = [FileProtectionMode irmDeprecated];
        }
        
        onSuccessfulLoadWithProtectionMode(fileProtectionMode, unprotectedData);
    };
    
    void (^onCancel)() = ^()
    {
        self.isInProgress = NO;
    };
    
    if ([filePath hasSuffix:[[FileProtectionMode pfile] fileExtension]])
    {
        fileProtectionMode = [FileProtectionMode pfile];
        [self loadPfile:filePath onSuccess:onSuccessfulLoad onCancel:onCancel];
    }
    else if ([filePath hasSuffix:[[FileProtectionMode irm] fileExtension]])
    {
        fileProtectionMode = [FileProtectionMode irm];
        [self loadCustomProtectedFile:filePath onSuccess:onSuccessfulCustomLoad onCancel:onCancel];
    }
    else if ([filePath hasSuffix:[[FileProtectionMode none] fileExtension]])
    {
        fileProtectionMode = [FileProtectionMode none];
        
        // The RMS SDK supports loading plain text unprotected files as well as protected files
        [self loadPfile:filePath onSuccess:onSuccessfulLoad onCancel:onCancel];
    }
    
    [self updateWindowTitle];
}

#pragma mark UI updates

- (void)updateWindowTitle
{
    NSMutableString *newWindowTitle = [[NSMutableString alloc] init];
    
    // Protection mode
    if (self.fileProtectionMode.titleDisplayText.length > 0)
    {
        [newWindowTitle appendFormat:@"[%@] ", self.fileProtectionMode.titleDisplayText];
    }
    
    // File name
    [newWindowTitle appendString:self.fileTitle];
    
    // Dirty indication
    if (self.wasFileModified)
    {
        [newWindowTitle appendString:@" *"];
    }
    
    [self.window setTitle:[newWindowTitle description]];
    newWindowTitle = nil;
}

- (void)updateWindowContent
{
    [self updateWindowTitle];
    
    if (self.fileProtectionMode == nil ||
        self.fileProtectionMode == [FileProtectionMode none])
    {
        [self hideProtectionBar];
    }
    else
    {
        [self showProtectionBar];
    }
}

- (void)hideProtectionBar
{
    [[self protectionBarContainerView] setSubviews:[NSArray array]];
}

- (void)showProtectionBar
{
    if (self.protectionPolicy != nil)
    {
        // Remove previous MSProtectionBars before adding the new one.
        NSArray* subViews = self.protectionBarContainerView.subviews;
        for (NSView *aView in subViews)
        {
            [aView removeFromSuperview];
        }

        MSProtectionBarViewController *protectionBarViewController = [[MSProtectionBarViewController alloc] initWithProtectionPolicy:self.protectionPolicy supportedAppRights:self.supportedAppRights];
        protectionBarViewController.delegate = self;
        
        // Hold a strong reference to the protection bar view controller
        self.protectionBar = protectionBarViewController;
        
        NSView *protectionBar = protectionBarViewController.view;
        [protectionBar setTranslatesAutoresizingMaskIntoConstraints:NO];

        NSDictionary *protectionBarDict = NSDictionaryOfVariableBindings(protectionBar);
       
        [[self protectionBarContainerView] addSubview:protectionBar];
        [[self protectionBarContainerView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[protectionBar]|" options:0 metrics:nil views:protectionBarDict]];
        [[self protectionBarContainerView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[protectionBar]|" options:0 metrics:nil views:protectionBarDict]];
    }
}

#pragma mark Encoding-related methods

- (NSData *)addBomToData:(NSData *)data encoding:(NSStringEncoding)encoding
{
    NSDictionary *encodingsDictionary = [self encodingToBomDictionary];
    NSNumber *encodingKey = [NSNumber numberWithInteger:encoding];
    NSData *encodingHeader = [encodingsDictionary objectForKey:encodingKey];
    
    if ([self doesData:data startWithHeader:encodingHeader])
    {
        return data;
    }
    else
    {
        NSMutableData *newData = [[NSMutableData alloc] initWithData:encodingHeader];
        [newData appendData:data];
        return newData;
    }
}

- (NSDictionary *)encodingToBomDictionary
{
    static Byte utf8HeaderBytes[] = {0xEF, 0xBB, 0xBF};
    static Byte utf16leHeaderBytes[] = { 0xFF, 0xFE };
    static Byte utf16beHeaderBytes[] = { 0xFE, 0xFF };
    static Byte utf32leHeaderBytes[] = { 0xFF, 0xFE, 0x00, 0x00 };
    static Byte utf32beHeaderBytes[] = { 0x00, 0x00, 0xFE, 0xFF };
    
    NSData *utf8Header = [NSData dataWithBytes:utf8HeaderBytes length:sizeof(utf8HeaderBytes)];
    NSData *utf16leHeader = [NSData dataWithBytes:utf16leHeaderBytes length:sizeof(utf16leHeaderBytes)];
    NSData *utf16beHeader = [NSData dataWithBytes:utf16beHeaderBytes length:sizeof(utf16beHeaderBytes)];
    NSData *utf32leHeader = [NSData dataWithBytes:utf32leHeaderBytes length:sizeof(utf32leHeaderBytes)];
    NSData *utf32beHeader = [NSData dataWithBytes:utf32beHeaderBytes length:sizeof(utf32beHeaderBytes)];
    
    NSNumber *utf8 = [NSNumber numberWithInteger:NSUTF8StringEncoding];
    NSNumber *utf16be = [NSNumber numberWithInteger:NSUTF16BigEndianStringEncoding];
    NSNumber *utf16le = [NSNumber numberWithInteger:NSUTF16LittleEndianStringEncoding];
    NSNumber *utf32be = [NSNumber numberWithInteger:NSUTF32BigEndianStringEncoding];
    NSNumber *utf32le = [NSNumber numberWithInteger:NSUTF32LittleEndianStringEncoding];
    
    NSDictionary *encodingToBomDict = @{utf8 : utf8Header,
                                        utf16le : utf16leHeader,
                                        utf16be : utf16beHeader,
                                        utf32le : utf32leHeader,
                                        utf32be : utf32beHeader};
    
    return encodingToBomDict;
}

// Gets the string encoding of the data, based on its BOM
- (NSStringEncoding)getStringEncoding:(NSData *)data
{
    NSDictionary *encodingToBom = [self encodingToBomDictionary];
    
    NSNumber *utf8 = [NSNumber numberWithInteger:NSUTF8StringEncoding];
    NSNumber *utf16be = [NSNumber numberWithInteger:NSUTF16BigEndianStringEncoding];
    NSNumber *utf16le = [NSNumber numberWithInteger:NSUTF16LittleEndianStringEncoding];
    NSNumber *utf32be = [NSNumber numberWithInteger:NSUTF32BigEndianStringEncoding];
    NSNumber *utf32le = [NSNumber numberWithInteger:NSUTF32LittleEndianStringEncoding];
    
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    
    // Because we check for encodings according to the bytes we start with, we need to
    // check for UTF-32 encodings first, because their sequence is longer
    for (NSNumber *encoding in @[utf32be, utf32le, utf8, utf16be, utf16le])
    {
        NSData *encodingHeader = [encodingToBom objectForKey:encoding];
        if ([self doesData:data startWithHeader:encodingHeader])
        {
            stringEncoding = (NSStringEncoding)[encoding unsignedIntegerValue];
            return stringEncoding;
        }
    }
    
    NSLog(@"Could not detect encoding, assuming UTF-8");
    return stringEncoding;
}

- (BOOL)doesData:(NSData *)data startWithHeader:(NSData *)header
{
    if (data.length < header.length) {
        return NO;
    }
    
    NSData *firstBytes = [data subdataWithRange:NSMakeRange(0, header.length)];
    return [firstBytes isEqualToData:header];
}

#pragma mark TextView delegate methods

- (void)textDidChange:(NSNotification *)notification
{
    self.wasFileModified = YES;
}

- (void)dealloc
{
    _textView = nil;
}

#pragma mark MSPolicyPicker delegate methods

- (void)didCancelProtection:(MSPolicyPicker *)sender
{
    NSLog(@"Protection cancelled");
    [self showProtectionBar];
    self.isInProgress = NO;
}

- (void)didSelectProtection:(MSProtectionPolicy *)protectionPolicy picker:(MSPolicyPicker *)sender
{
    // If we start with a policy which uses a deprecated algorithm and switch to one which does not,
    // or the other way around, we would like the user to select the protection mode again upon save.
    if ((self.protectionPolicy != nil) &&
        (self.protectionPolicy.doesUseDeprecatedAlgorithm != protectionPolicy.doesUseDeprecatedAlgorithm))
    {
        self.fileProtectionMode = [FileProtectionMode undefined];
    }
    
    self.protectionPolicy = protectionPolicy;
    if (self.protectionPolicy.doesUseDeprecatedAlgorithm)
    {
        // This is the only supported protection mode in this case
        self.fileProtectionMode = [FileProtectionMode irmDeprecated];
    }
    else if (self.fileProtectionMode == [FileProtectionMode none])
    {
        self.fileProtectionMode = [FileProtectionMode undefined];
    }
    
    self.isInProgress = NO;
}

- (void)didSelectNoProtection:(MSPolicyPicker *)sender
{
    self.protectionPolicy = nil;
    self.fileProtectionMode = [FileProtectionMode none];
    self.isInProgress = NO;
}

- (void)willShowPolicyPickerView:(MSPolicyPicker *)sender
{
    self.isInProgress = NO;
}

- (void)didDismissPolicyPickerView:(MSPolicyPicker *)sender
{
    // Returning the "in progress" indication so that the window will remain locked
    self.isInProgress = YES;
}

- (void)didFailWithError:(NSError *)error picker:(MSPolicyPicker *)sender
{
    [self handleError:error];
}

#pragma mark MSProtectionBar delegate methods

- (void)didUserTapCloseButton:(MSProtectionBarViewController *)sender
{
    [self hideProtectionBar];
}

#pragma mark Window delegate methods

- (BOOL)windowShouldClose:(id)sender
{
    return [self saveModifiedFile];
}

#pragma mark Menu-related delegate methods

// We've implemented this method in order to make sure the menu items
// get validated according to whether they are enabled or not.
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL action = [anItem action];
    if (action == @selector(openDocument:) || action == @selector(newDocument:) || action == @selector(onProtect:) || action == @selector(onProtectDeprecated:))
    {
        return !self.isInProgress;
    }
    if (action == @selector(saveDocument:) || action == @selector(saveDocumentAs:) || action == @selector(onSaveAs:))
    {
        return self.protectionPolicy == nil || [self.protectionPolicy accessCheck:[MSEditableDocumentRights exportable]];
    }
    return [self.textView validateUserInterfaceItem:anItem];
}

#pragma mark - Protection-related methods

// Protection related method
- (void)pickProtectionPolicyWithCurrentPolicy:(MSProtectionPolicy *)policy preferDeprecatedAlgorithms:(BOOL)preferDeprecatedAlgorithms
{
    MSPolicyPicker *picker = [[MSPolicyPicker alloc] init];
    
    picker.policy = policy;
    picker.preferDeprecatedAlgorithms = preferDeprecatedAlgorithms;
    picker.delegate = self;
    [picker pickProtectionPolicyModalForWindow:self.window];
}

// Protection related method
- (void)saveProtectedTextFile:(NSString *)filePath
                dataToProtect:(NSData *)dataToProtect
                      success:(void(^)())successCompletionBlock
                        error:(NSError **)error
{
    [MSMutableProtectedData protectedDataWithPolicy:self.protectionPolicy
                              originalFileExtension:@"txt"
                                               path:filePath
                                    completionBlock:^(MSMutableProtectedData *data, NSError *innerError) {
                                        if (innerError == nil)
                                        {
                                            [data appendData:dataToProtect error:&innerError];
                                            if (innerError == nil)
                                            {
                                                [data close:&innerError];
                                                if (innerError == nil)
                                                {
                                                    NSLog(@"Successfully published file");
                                                    successCompletionBlock();
                                                }
                                            }
                                        }
                                        
                                        if ((innerError != nil) && (error != nil))
                                        {
                                            *error = innerError;
                                        }
                                    }];
}

// Protection related method
- (void)saveCustomProtectedTextFile:(NSString *)filePath
                      dataToProtect:(NSData *)dataToProtect
                            success:(void(^)())successCompletionBlock
                              error:(NSError **)error
{
    NSMutableData *unprotectedData = [NSMutableData dataWithData:dataToProtect];
    NSMutableData *backingData = [[NSMutableData alloc] init];
    
    //Get the PL from a given policy
    NSData *pl = [self.protectionPolicy serializedPolicy];
    uint32_t protectedContentLength = (uint32_t)[self.protectionPolicy getEncryptedContentLength:unprotectedData.length];
    
    // In deprecated algorithm mode the content must be 16 bytes aligned.
    // Increasing the size of the stream will add a padding with 0s.
    if (self.protectionPolicy.doesUseDeprecatedAlgorithm == TRUE)
    {
        if ((protectedContentLength % kDeprecatedAlgAlignement) != 0)
        {
            protectedContentLength = (((protectedContentLength / kDeprecatedAlgAlignement) + 1) * kDeprecatedAlgAlignement);
        }
        
        [unprotectedData setLength:protectedContentLength];
    }
    
    //Write header information to backing data including the PL
    /*-------------------------------------------
     | PL length | PL | ContetSizeLength |
     -------------------------------------------*/
    uint32_t plLength = (uint32_t)[pl length];
    [backingData appendData:[NSData dataWithBytes:&plLength length:sizeof(plLength)]];
    [backingData appendData:pl];
    [backingData appendData:[NSData dataWithBytes:&protectedContentLength length:sizeof(protectedContentLength)]];
    
    NSUInteger headerLength = sizeof(plLength) + plLength + sizeof(protectedContentLength);
    [MSMutableCustomProtectedData customProtectorWithProtectionPolicy:self.protectionPolicy
                                                          backingData:backingData
                                               protectedContentOffset:headerLength
                                                      completionBlock:^(MSMutableCustomProtectedData *customProtectedData, NSError *innerError)
     {
         if (innerError != nil)
         {
             NSLog(@"Protection failed on file: %@, error: %@", filePath, innerError);
             *error = innerError;
         }
         else
         {
             [customProtectedData updateData:unprotectedData error:&innerError];
             
             if (innerError != nil)
             {
                 NSLog(@"Protection failed");
                 *error = innerError;
             }
             else
             {
                 [customProtectedData close:&innerError];
                 if (innerError != nil)
                 {
                     NSLog(@"Error closing protected data");
                     *error = innerError;
                 }
                 else
                 {
                     NSLog(@"Finished publishing to file: %@", filePath);
                     
                     [backingData writeToFile:filePath atomically:YES];
                     successCompletionBlock();
                 }
             }
             
         }
     }];
}

// Protection related method
- (void)loadPfile:(NSString *)pfilePath onSuccess:(void(^)(NSData*))successBlock onCancel:(void(^)())cancelBlock
{
    self.isInProgress = YES;
    [MSProtectedData protectedDataWithProtectedFile:pfilePath completionBlock:^(MSProtectedData *data, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (error == nil)
            {
                if (data == nil)
                {
                    // If data == nil, it means the user has cancelled the operation.
                    cancelBlock();
                    return;
                }
                
                self.protectionPolicy = data.protectionPolicy;
                
                NSData *unprotectedData = [data retrieveData];
                successBlock(unprotectedData);
            }
            else
            {
                NSLog(@"Got error: %@", error);
                [self handleError:error];
            }
        });
    }];
}

// Protection related method
- (void)loadCustomProtectedFile:(NSString *)filePath onSuccess:(void(^)(NSData*))successBlock onCancel:(void(^)())cancelBlock
{
    // Read header information from protectedData and extract the  PL
    /*-------------------------------------------
     | PL length | PL | ContetSizeLength |
     -------------------------------------------*/
    NSFileHandle *irmFile = [NSFileHandle fileHandleForReadingAtPath:filePath];
    NSData *plSizeData = [irmFile readDataOfLength:sizeof(uint32_t)];
    uint32_t plSize;
    [plSizeData getBytes:&plSize range:NSMakeRange(0, sizeof(uint32_t))];
    
    // get the PL and protectedData
    NSData *pl = [irmFile readDataOfLength:plSize];
    uint32_t protectedContentSize;
    NSData *protectedContentSizeData = [irmFile readDataOfLength:sizeof(uint32_t)];
    [protectedContentSizeData getBytes:&protectedContentSize range:NSMakeRange(0, sizeof(uint32_t))];
    NSData *protectedData = [irmFile readDataOfLength:protectedContentSize];
    
    // Get the protection policy , this is async method as it hits the REST service
    // for content key and usage restrictions
    [MSProtectionPolicy protectionPolicyWithSerializedLicense:pl
                                              completionBlock:^(MSProtectionPolicy *protectionPolicy, NSError *error)
     {
         if (error == nil)
         {
             if (protectionPolicy == nil)
             {
                 // If we got here it means the user has cancelled the operation.
                 cancelBlock();
                 return;
             }
             
             // Create the MSCustomProtectedData used for decrypting the content
             // The content start position is the header length
             // The decrypted content size is NSUIntegerMax since the content ends in EOF
             [MSCustomProtectedData customProtectedDataWithPolicy:protectionPolicy
                                                    protectedData:protectedData
                                             contentStartPosition:0
                                                      contentSize:protectedContentSize
                                                  completionBlock:^(MSCustomProtectedData *customProtectectedData,
                                                                    NSError *innerError)
              {
                  dispatch_async(dispatch_get_main_queue(),^{
                      // Note: We need to store the protection policy in order to use it with the policy viewer
                      if (innerError != nil)
                      {
                          NSLog(@"Failed to open the protected file, error: %@", innerError);
                          [self handleError:innerError];
                      }
                      else
                      {
                          self.protectionPolicy = protectionPolicy;
                          
                          // Check if the user has the right to view the data
                          if (![self.protectionPolicy accessCheck:[MSCommonRights view]])
                          {
                              NSError *noViewError = [[NSError alloc] initWithDomain:@"No view rights were given for the document." code:0 userInfo:nil];
                              [self handleError:noViewError];
                          }
                          else
                          {
                              // Read the content from the custom protector, this will decrypt the data
                              NSMutableData *decryptedMutableData = [NSMutableData dataWithData:customProtectectedData.retrieveData];
                              
                              successBlock(decryptedMutableData);
                          }
                      }
                  });
              }];
         }
         else
         {
             NSLog(@"Failed to get protected policy, error: %@", error);
             [self handleError:error];
         }
     }];
}

@end
