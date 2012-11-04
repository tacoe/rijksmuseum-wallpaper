//
//  RBAppDelegate.m
//  Rijksbehang
//
//  Created by Taco Ekkel on 31-10-12.
//  Copyright (c) 2012 Taco Ekkel. All rights reserved.
//

#import "RBAppDelegate.h"

@implementation RBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self populateCollections];
    [self activateStatusMenu];
    [self retrieveState];
    [self setTimer];
}

- (void)storeState {
    NSLog(@"Storing state");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:activeCollection forKey:@"activeCollection"];
    [defaults setInteger:activeImageIndex forKey:@"currentIndex"];
    [defaults setInteger:refreshTimeout forKey:@"refreshTimeout"];
    [defaults synchronize];
}

- (void)retrieveState {
    //retrieve state
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    activeCollection = [defaults objectForKey:@"activeCollection"];
    if(activeCollection)
    {
        activeImageIndex = (int)[defaults integerForKey:@"currentIndex"];
        refreshTimeout = (int)[defaults integerForKey:@"refreshTimeout"];
    }
    else
    {
        NSLog(@"first use - setting default, saving");
        activeCollection = @"Taco's Favorites";
        activeImageIndex = 0;
        refreshTimeout = 60*60;
        [self storeState];
    }
    NSLog(@"Restored state.activeCollection: %@, activeImageIndex: %d, refreshTimeout: %ld", activeCollection, activeImageIndex, refreshTimeout);

    //update part of the UI
    switch(refreshTimeout){
        case SECONDS_HOUR: [refreshRateButton setSelectedSegment:1]; break;
        case SECONDS_DAY: [refreshRateButton setSelectedSegment:2]; break;
        case SECONDS_WEEK: [refreshRateButton setSelectedSegment:3]; break;
        default: [refreshRateButton setSelectedSegment:0];
    }
    [collectionDropdown selectItemWithTitle:activeCollection];
    [self loadCollection: activeCollection];
    
    //set wallpaper, which sets the remainder of the UI
    [self setWallpaper];
}

- (void)setTimer {
    if(!globalTimer) globalTimer = [NSTimer new];
    [globalTimer invalidate];
    if(refreshTimeout > 0)
        globalTimer = [NSTimer scheduledTimerWithTimeInterval: refreshTimeout
                                             target: self
                                           selector: @selector(tick:)
                                           userInfo: NULL
                                            repeats: YES];
}

- (IBAction)showPreferences:(id)sender {
    [[self window] makeKeyAndOrderFront:self];
}

-(IBAction)clickRefreshRate:(id)sender {
    switch ([refreshRateButton selectedSegment])
    {
        case 1:  refreshTimeout = SECONDS_HOUR; break;
        case 2:  refreshTimeout = SECONDS_DAY; break;
        case 3:  refreshTimeout = SECONDS_WEEK; break;
        default: refreshTimeout = 0; break;
    }
    [self setTimer];
    [self storeState];
    NSLog(@"refreshrate set to %ld seconds", refreshTimeout);
}

-(IBAction)clickNavigate:(id)sender {
    switch ([navigateButton selectedSegment])
    {
        case 0:
            [self previousWallpaper];
            break;
        case 1:
            [self nextWallpaper];
            break;
    }
}

-(IBAction) nextFromMenu:(id)sender {
    [self nextWallpaper];
}

-(IBAction) previousFromMenu:(id)sender {
    [self previousWallpaper];
}

-(void) nextWallpaper {
    activeImageIndex++;
    if(activeImageIndex >= [activeImageCodes count]) activeImageIndex = 0;
    [self storeState];
    [self setWallpaper];
}


-(void) previousWallpaper {
    activeImageIndex--;
    if(activeImageIndex < 0) activeImageIndex = (int)[activeImageCodes count]-1;
    [self storeState];
    [self setWallpaper];
}

-(IBAction)selectCollection:(id)sender {
    NSLog(@"select collection");
    activeCollection = [(NSMenuItem *)[collectionDropdown selectedItem] title];
    activeImageIndex = 0;
    [self storeState];
    [self loadCollection: activeCollection];
    [self setWallpaper];
}

- (void)disableUI {
    [spinner startAnimation:self];
    [progressBar startAnimation:self];
    [progressBar setDoubleValue:0.0f];
    [collectionDropdown setEnabled:FALSE];
    [refreshRateButton setEnabled:FALSE];
    [navigateButton setEnabled:FALSE];
    [nextItem setEnabled:FALSE];
    [previousItem setEnabled:FALSE];
    [quitItem setEnabled:FALSE];
    isLoading = TRUE;
}

- (void)enableUI {
    [spinner stopAnimation:self];
    [progressBar stopAnimation:self];
    [progressBar setDoubleValue:0.0f];
    [collectionDropdown setEnabled:TRUE];
    [refreshRateButton setEnabled:TRUE];
    [navigateButton setEnabled:TRUE];
    [nextItem setEnabled:TRUE];
    [previousItem setEnabled:TRUE];
    [quitItem setEnabled:TRUE];
    isLoading = FALSE;
}

- (void)populateCollections {
    NSLog(@"Populate collections");

    collectionDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                @"SK-A-4868,SK-A-4,SK-A-175,SK-A-2298,SK-A-3592,SK-A-4688,SK-A-4830,SK-A-4839,SK-A-2382", @"Taco's Favorites",
                @"SK-A-2344,SK-C-251,SK-A-2860,SK-A-1595", @"Johannes Vermeer",
                @"SK-A-4691,SK-C-5,SK-C-216,SK-C-597,SK-A-4050,SK-C-6,SK-A-4885,SK-A-3981,SK-A-3340,SK-A-3982,SK-A-1935,SK-A-4674", @"Rembrandt van Rijn",
                @"SK-A-1892,SK-A-1328,SK-A-1505,SK-A-2670,SK-A-3263,SK-A-3592", @"Impressionism",
                @"SK-A-5002,SK-C-1702,SK-C-1703,RP-P-2008-90", @"Cobra",
                @"BK-1973-158,BK-1990-1,BK-BR-J-233,RP-P-1912-2395,RP-F-F20723", @"Art Nouveau",
                @"RP-T-1980-10,SK-A-4644,SK-A-4868", @"Romanticism",
                @"SK-A-670,SK-A-3746,SK-A-3120,SK-A-1320,SK-A-3247,SK-A-3286,SK-A-1718,SK-A-1705,SK-A-802,SK-A-1848,SK-A-123,SK-A-4644,SK-A-3949,SK-A-70,SK-A-1058,SK-A-1610,SK-A-2313,SK-A-321,SK-A-443,SK-C-109,SK-C-206,SK-A-317,SK-A-1774,SK-A-1935,SK-A-2290,SK-A-3230,SK-A-2298,SK-A-2264,SK-A-3072,SK-C-211,SK-A-1505,SK-A-2291,SK-A-4875,SK-A-1923,SK-A-2670,SK-A-2525,SK-A-2983,SK-A-3602,SK-A-3597,SK-A-347,SK-A-1293,SK-A-1299,SK-A-1892,SK-A-1196,SK-A-2355,SK-A-1775,SK-A-4133", @"Landscapes",
                @"RP-P-1958-281,RP-P-1958-279,RP-P-1958-298,RP-P-1958-293,RP-P-1958-294,RP-P-1958-272",@"Katushika Hukosai",
                @"BK-1963-101,BK-NM-88,BK-NM-13150,BK-NM-3888,AK-MAK-240,AK-MAK-187,AK-MAK-84,AK-RAK-2007-1-A,AK-RAK-2007-1-B",@"Masterpieces: Sculptures",
                @"SK-A-4225,SK-A-188,SK-A-2249,SK-C-87,SK-A-3948,SK-A-2248,SK-A-2576,SK-A-240",@"Rococo: Paintings",
                @"BK-16431,BK-16676,BK-17397,BK-1959-19,BK-1961-63,BK-1964-13,BK-1964-14-A",@"Rococo: Objects",
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
    activeImageCodes = [(NSString *)[collectionDictionary objectForKey:activeCollection] componentsSeparatedByString:@","];
    NSLog(@"Loaded codes for collection %@", key);
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
    if(isLoading) return;

    activeImageIndex++;
    if(activeImageIndex >= [activeImageCodes count]) activeImageIndex = 0;
    
    [self setWallpaper];
}

- (void)setWallpaper {
    [countLabel setStringValue:[NSString stringWithFormat:@"%d of %ld",activeImageIndex+1,[activeImageCodes count]]];
    filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                          [NSString stringWithFormat: @"%@.jpg",[activeImageCodes objectAtIndex:activeImageIndex]]];
    NSLog(@"Loading %@", filePath);

    if([[NSFileManager defaultManager] fileExistsAtPath: filePath])
    {
        [self setWallpaper:filePath];
    }
    else if(!isLoading)
    {
        [self disableUI];
        NSString *remotePath = [NSString stringWithFormat:@"https://www.rijksmuseum.nl/assetimage2.jsp?id=%@",
                                [activeImageCodes objectAtIndex:activeImageIndex]];
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
