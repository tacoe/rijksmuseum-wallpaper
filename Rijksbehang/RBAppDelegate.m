//
//  RBAppDelegate.m
//  Rijksbehang
//
//  Created by Taco Ekkel on 31-10-12.
//  Copyright (c) 2012 Taco Ekkel. All rights reserved.
//

#import "RBAppDelegate.h"

@implementation RBAppDelegate

NSTimer *timer;
__strong NSStatusItem *statusitem;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    defaults = [NSUserDefaults standardUserDefaults];
    
    [self populateCollections];
    [self activateStatusMenu];
    
    globalTimer = [NSTimer new];
    refreshTimeout = 60*60;
    
    [self setTimer];
    [self downloadWallpaper];    
}

- (void)setTimer {
    if(refreshTimeout > 0)
        globalTimer = [NSTimer scheduledTimerWithTimeInterval: refreshTimeout
                                             target: self
                                           selector: @selector(tick:)
                                           userInfo: NULL
                                            repeats: YES];
    else
        [timer invalidate];
}

- (IBAction)showPreferences:(id)sender {
    [[self window] makeKeyAndOrderFront:self];
}

-(IBAction)clickRefreshRate:(id)sender {
    switch ([refreshRateButton selectedSegment])
    {
        case 1:  refreshTimeout = 60*60; break;
        case 2:  refreshTimeout = 60*60*24; break;
        case 3:  refreshTimeout = 60*60*24*7; break;
        default: refreshTimeout = 0; break;
    }
    [self setTimer];
    NSLog(@"refreshrate set to %ld seconds", refreshTimeout);
}

-(IBAction)clickNavigate:(id)sender {
    switch ([navigateButton selectedSegment])
    {
        case 0:
            currentIndex--;
            if(currentIndex < 0) currentIndex = (int)[currentCodes count]-1;
            break;
        case 1:
            currentIndex++;
            if(currentIndex >= [currentCodes count]) currentIndex = 0;
            break;
    }
    [self downloadWallpaper];
}

-(IBAction)selectCollection:(id)sender {
    NSLog(@"select collection");
    activeCollection = [(NSMenuItem *)[collectionDropdown selectedItem] title];
    [self loadCollection: activeCollection];
}

- (void)disableUI {
    [spinner startAnimation:self];
    [progressBar startAnimation:self];
    [progressBar setDoubleValue:0.0f];
    [collectionDropdown setEnabled:FALSE];
    [refreshRateButton setEnabled:FALSE];
    [navigateButton setEnabled:FALSE];
}

- (void)enableUI {
    [spinner stopAnimation:self];
    [progressBar stopAnimation:self];
    [progressBar setDoubleValue:0.0f];
    [collectionDropdown setEnabled:TRUE];
    [refreshRateButton setEnabled:TRUE];
    [navigateButton setEnabled:TRUE];
}

- (void)populateCollections {
    NSLog(@"Populate collections");

    collectionDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                @"SK-A-4,SK-A-175,SK-A-2298,SK-A-3584,SK-A-3592,SK-A-4688,SK-A-4830,SK-A-4839,SK-A-4868,SK-C-5,SK-A-2382", @"Taco's Favorites",
                @"SK-A-2344,SK-C-251,SK-A-2860,SK-A-1595", @"Johannes Vermeer",
                @"SK-A-4691,SK-C-5,SK-C-216,SK-C-597,SK-A-4050,SK-C-6,SK-A-4885,SK-A-3981,SK-A-3340,SK-A-3982,SK-A-1935,SK-A-4674", @"Rembrandt van Rijn",
                @"SK-A-1892,SK-A-1328,SK-A-1505,SK-A-2670,SK-A-3263,SK-A-3592", @"Impressionism",
                @"SK-A-5002,SK-C-1702,SK-C-1703,RP-P-2008-90", @"Cobra",
                @"RP-T-1980-10,SK-A-4644,SK-A-4868", @"Romantiek",
                @"SK-A-670,SK-A-3746,SK-A-3120,SK-A-1320,SK-A-3247,SK-A-3286,SK-A-1718,SK-A-1705,SK-A-802,SK-A-1848,SK-A-123,SK-A-4644,SK-A-3949,SK-A-70,SK-A-1058,SK-A-1610,SK-A-2313,SK-A-321,SK-A-443,SK-C-109,SK-C-206,SK-A-317,SK-A-1774,SK-A-1935,SK-A-2290,SK-A-3230,SK-A-2298,SK-A-2264,SK-A-3072,SK-C-211,SK-A-1505,SK-A-2291,SK-A-4875,SK-A-1923,SK-A-2670,SK-A-2525,SK-A-2983,SK-A-3602,SK-A-3597,SK-A-347,SK-A-1293,SK-A-1299,SK-A-1892,SK-A-1196,SK-A-2355,SK-A-1775,SK-A-4133", @"Landscapes",
                nil];

    [collectionDropdown removeAllItems];
    [collectionDropdown addItemsWithTitles: [[collectionDictionary allKeys]
                                             sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];

    [collectionDropdown selectItemAtIndex:0];
    activeCollection = [[[collectionDictionary allKeys]
                        sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:0];
    [self loadCollection: activeCollection];
}

- (void)loadCollection:(NSString *)key {
    currentIndex = 0;
    currentCodes = [(NSString *)[collectionDictionary objectForKey:activeCollection] componentsSeparatedByString:@","];
    [self downloadWallpaper];
}

- (void)activateStatusMenu {
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    statusitem = [bar statusItemWithLength:NSVariableStatusItemLength];
    
    NSImage *img = [NSImage imageNamed:@"rijksicon.icns"];
    [img setSize:NSMakeSize(16,16)];
    [statusitem setImage: img];
    [statusitem setHighlightMode: YES];
    [statusitem setMenu: statusmenu];
}

- (void)tick:(NSTimer *)t {
    NSLog(@"TICK");
    [self downloadWallpaper];
}

- (void)downloadWallpaper {
    NSLog(@"Object index: %d", currentIndex);
    [countLabel setStringValue:[NSString stringWithFormat:@"%d of %ld",currentIndex+1,[currentCodes count]]];
    filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                          [NSString stringWithFormat: @"%@.jpg",[currentCodes objectAtIndex:currentIndex]]];
    NSLog(@"Loading %@", filePath);

    if([[NSFileManager defaultManager] fileExistsAtPath: filePath])
    {
        [self setWallpaper:filePath];
    }
    else
    {
        [self disableUI];
        NSString *remotePath = [NSString stringWithFormat:@"https://www.rijksmuseum.nl/assetimage2.jsp?id=%@",
                                [currentCodes objectAtIndex:currentIndex]];
        responseData = [NSMutableData data];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:remotePath]];
        
        if (![[NSURLConnection alloc] initWithRequest:request delegate:self])
            [[NSAlert alertWithMessageText:@"Can't connect to www.rijksmuseum.nl" defaultButton:@"Bummer"
                           alternateButton:nil otherButton:nil informativeTextWithFormat:nil] runModal];
        else
            NSLog(@"Downloading...");
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"DidReceiveResponse");
    totalFileSize = response.expectedContentLength;
    currentFileSize = 0;
    [responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    currentFileSize += [data length];
    [progressBar setDoubleValue:(100.0f*currentFileSize)/totalFileSize];
    [responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self enableUI];
    [[NSAlert alertWithError:error] runModal];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Saving to: %@", filePath);
    [responseData writeToFile:filePath atomically:YES];
    [self setWallpaper:filePath];
    [self enableUI];
}


- (void)setWallpaper:(NSString *)filePath
{
    NSScreen *curscreen = [NSScreen mainScreen];
    NSError *error = nil;
    NSURL *imageurl = [NSURL URLWithString: [NSString stringWithFormat:@"file://%@", filePath]];
    
    NSDictionary *curoptions = [NSDictionary dictionaryWithObjectsAndKeys:nil,
                             NSWorkspaceDesktopImageFillColorKey, [NSNumber numberWithBool:NO],
                             NSWorkspaceDesktopImageAllowClippingKey, [NSNumber numberWithInteger:NSImageScaleProportionallyUpOrDown],
                             NSWorkspaceDesktopImageScalingKey, nil];
    
    if (![[NSWorkspace sharedWorkspace] setDesktopImageURL: imageurl
                                            forScreen: curscreen
                                              options: curoptions
                                                error: &error])
    {
        [NSApp presentError:error];
    }
}

@end
