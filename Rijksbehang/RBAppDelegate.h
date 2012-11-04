//
//  RBAppDelegate.h
//  Rijksbehang
//
//  Created by Taco Ekkel on 31-10-12.
//  Copyright (c) 2012 Taco Ekkel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RBAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *statusmenu;
    IBOutlet NSPopUpButton *collectionDropdown;
    IBOutlet NSProgressIndicator *spinner;
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSSegmentedControl *navigateButton;
    IBOutlet NSSegmentedControl *refreshRateButton;
    IBOutlet NSTextField *countLabel;
    IBOutlet NSMenuItem *nextItem;
    IBOutlet NSMenuItem *previousItem;
    IBOutlet NSMenuItem *quitItem;
}

@property (assign) IBOutlet NSWindow *window;
-(IBAction)showPreferences:(id)sender;
-(IBAction)clickRefreshRate:(id)sender;
-(IBAction)clickNavigate:(id)sender;
-(IBAction)selectCollection:(id)sender;
-(IBAction)nextFromMenu:(id)sender;
-(IBAction)previousFromMenu:(id)sender;

@end

NSMutableData *responseData;
NSString      *filePath;
NSDictionary  *collectionDictionary;
NSString      *activeCollection = nil;
int           activeImageIndex = 0;
NSArray       *activeImageCodes;
NSTimer       *globalTimer = nil;
Boolean       isLoading = FALSE;

__strong NSStatusItem *statusitem; // make sure ARC doesn't toss it

long totalFileSize = 0;
long currentFileSize = 0;
long refreshTimeout = 0;

const int SECONDS_HOUR = 60 * 60;
const int SECONDS_DAY = SECONDS_HOUR * 24;
const int SECONDS_WEEK = SECONDS_DAY * 7;

