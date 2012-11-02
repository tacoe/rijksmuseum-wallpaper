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
}

@property (assign) IBOutlet NSWindow *window;
-(IBAction)showPreferences:(id)sender;
-(IBAction)clickRefreshRate:(id)sender;
-(IBAction)clickNavigate:(id)sender;
-(IBAction)selectCollection:(id)sender;

@end

NSMutableData *responseData;
NSString *code;
NSString *filePath;
NSDictionary *collectionDictionary;
NSString *activeCollection;
int currentIndex = 0;
NSArray *currentCodes;
NSTimer *globalTimer;

long totalFileSize = 0;
long currentFileSize = 0;
long refreshTimeout = 60*60;