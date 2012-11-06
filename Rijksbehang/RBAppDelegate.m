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
    [self setStoragePath];
    [self populateCollections];
    [self activateStatusMenu];
    [self retrieveState];
    [self setTimer];
}

- (void) setStoragePath {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    if ([paths count] == 0) [NSApp terminate: nil];
    storagePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Rijksmuseum Wallpaper"];
    NSError *error;
    BOOL success = [[NSFileManager defaultManager]
                        createDirectoryAtPath: storagePath
                        withIntermediateDirectories:YES
                        attributes:nil
                        error:&error];

    if (!success) [NSApp terminate: nil];
    NSLog(@"Our storage: %@", storagePath);
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
    [NSApp activateIgnoringOtherApps:YES];
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
    if(isLoading) return;
    activeImageIndex++;
    if(activeImageIndex >= [activeImageCodes count]) activeImageIndex = 0;
    [self storeState];
    [self setWallpaper];
}


-(void) previousWallpaper {
    if(isLoading) return;
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

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if(isLoading) return NSTerminateCancel; else return  NSTerminateNow;
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
                @"SK-A-4868,SK-A-1328,*NG-2011-20-5,SK-A-175,RP-P-OB-78.050,SK-A-2298,SK-A-3592,NG-2009-38-39,SK-A-4688,SK-A-4830,NG-1986-6-32,SK-A-2382,SK-A-4", @"Taco's Favorites",
                @"SK-A-4925,SK-A-1328,SK-A-3580,SK-A-2879,SK-A-3585,SK-A-3579,SK-A-2977,RP-T-1978-88,RP-F-00-565", @"George Hendrik Breitner",
                @"SK-A-2344,SK-C-251,SK-A-2860,SK-A-1595", @"Johannes Vermeer",
                @"SK-A-4691,SK-C-5,SK-C-216,SK-C-597,SK-A-4050,SK-C-6,SK-A-4885,SK-A-3981,SK-A-3340,SK-A-3982,SK-A-1935,SK-A-4674", @"Rembrandt van Rijn",
                @"SK-A-1892,SK-A-1328,SK-A-1505,SK-A-2670,SK-A-3263,SK-A-3592", @"Impressionism",
                @"SK-A-5002,SK-C-1702,SK-C-1703,RP-P-2008-90", @"Cobra",
                @"BK-1973-158,*BK-1975-101,*BK-1987-2,BK-1990-1,*BK-BR-J-233,RP-P-1912-2395,RP-F-F20723", @"Art Nouveau",
                @"RP-T-1980-10,SK-A-4644,SK-A-4868", @"Romanticism",
                @"SK-A-670,SK-A-3746,SK-A-3120,SK-A-1320,SK-A-3247,SK-A-3286,SK-A-1718,SK-A-1705,SK-A-802,SK-A-1848,SK-A-123,SK-A-4644,SK-A-3949,SK-A-70,SK-A-1058,SK-A-1610,SK-A-2313,SK-A-321,SK-A-443,SK-C-109,SK-C-206,SK-A-317,SK-A-1774,SK-A-1935,SK-A-2290,SK-A-3230,SK-A-2298,SK-A-2264,SK-A-3072,SK-C-211,SK-A-1505,SK-A-2291,SK-A-4875,SK-A-1923,SK-A-2670,SK-A-2525,SK-A-2983,SK-A-3602,SK-A-3597,SK-A-347,SK-A-1293,SK-A-1299,SK-A-1892,SK-A-1196,SK-A-2355,SK-A-1775,SK-A-4133", @"Landscapes",
                @"RP-P-1958-281,RP-P-1958-279,RP-P-1958-298,RP-P-1958-293,RP-P-1958-294,RP-P-1958-272",@"Katushika Hukosai",
                @"*BK-1963-101,*BK-NM-88,BK-NM-13150,*BK-NM-3888,*AK-MAK-240,*AK-MAK-187,*AK-MAK-84,*AK-RAK-2007-1-A,*AK-RAK-2007-1-B",@"Masterpieces: Sculptures",
                @"*SK-A-4225,SK-A-188,SK-A-2249,SK-C-87,SK-A-3948,*SK-A-2248,SK-A-2576,SK-A-240,*BK-16431,BK-16676,BK-17397,BK-1959-19,BK-1961-63,BK-1964-13,*BK-1964-14-A",@"Rococo",
                @"SK-A-831,SK-A-3467,*SK-C-1454,SK-A-1491,SK-A-3147-B,SK-A-1688,SK-A-2150,SK-A-500,SK-A-3901,SK-A-2312,BK-1962-33,SK-A-4294,*BK-NM-3888,BK-17045,*BK-NM-88,*BK-16986-A,BK-2010-16-1,BK-AM-12,*BK-1956-8", @"Gothic",
                @"SK-A-4921,SK-C-1349,SK-A-1967,SK-A-671,SK-A-670,SK-C-402,BK-17260-A,*BK-NM-12231-A,BK-NM-11163,RP-T-1940-577", @"Renaissance",
                @"SK-A-345,SK-A-4971,SK-A-2102,SK-A-1683,SK-A-3920,SK-A-4922,RP-T-1961-75,RP-P-OB-268,RP-T-1889-A-2056,RP-P-1962-65,RP-T-1899-A-4301,RP-P-1878-A-925,BK-1976-75,BK-17494,BK-18305,*BK-1998-74,BK-1960-13-A,BK-NM-13258,BK-BFR-417,BK-1985-10", @"Baroque",
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


- (NSString *)getImageFileCode:(NSString *)imagecode {
    return [imagecode stringByReplacingOccurrencesOfString:@"*" withString:@""];
}

- (NSString *)getOptionsFromCode:(NSString *)imagecode {
    if ([imagecode rangeOfString:@"*"].location != NSNotFound) return @"*"; else return @"";
}

- (void)setWallpaper {
    [countLabel setStringValue:[NSString stringWithFormat:@"%d of %ld",activeImageIndex+1,[activeImageCodes count]]];
    pendingImagePath = [storagePath stringByAppendingPathComponent:
                [NSString stringWithFormat: @"%@.jpg",[self getImageFileCode:[activeImageCodes objectAtIndex:activeImageIndex]]]];
    pendingImageOptions = [self getOptionsFromCode:[activeImageCodes objectAtIndex:activeImageIndex]];
    NSLog(@"Loading %@", pendingImagePath);

    if([[NSFileManager defaultManager] fileExistsAtPath: pendingImagePath])
    {
        [self setWallpaperImage:pendingImagePath withOptions:pendingImageOptions];
    }
    else if(!isLoading)
    {
        [self disableUI];
        NSString *remotePath = [NSString stringWithFormat:@"https://www.rijksmuseum.nl/assetimage2.jsp?id=%@",
                                [self getImageFileCode:[activeImageCodes objectAtIndex:activeImageIndex]]];
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
    NSLog(@"Saving to: %@", pendingImagePath);
    [responseData writeToFile:pendingImagePath atomically:YES];
    [self setWallpaperImage:pendingImagePath withOptions:pendingImageOptions];
    [self enableUI];
}


- (Boolean)allowClipping:(NSURL *)imageFileURL
{
    return true;
    // --- this is useful EXCEPT sometimes we do want portrait paintings fullscreen.
    // --- find a way to indicate/override in settings.
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)CFBridgingRetain(imageFileURL), NULL);
    if (imageSource == NULL) return FALSE;
    
    CFDictionaryRef imagePropertiesDictionary;

    imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource,0, NULL);
    
    CFNumberRef imageWidth = (CFNumberRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyPixelWidth);
    CFNumberRef imageHeight = (CFNumberRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyPixelHeight);
    
    int w = 0;
    int h = 0;
    
    CFNumberGetValue(imageWidth, kCFNumberIntType, &w);
    CFNumberGetValue(imageHeight, kCFNumberIntType, &h);
    
    CFRelease(imagePropertiesDictionary);
    CFRelease(imageSource);
    NSLog(@"Image dimensions: %d x %d px", w, h);
    if(h > 0)
        return(w > h);
    else return TRUE;
}

- (void)setWallpaperImage:(NSString *)filePath withOptions:(NSString *)options
{
    NSError *error = nil;
    NSURL *imageurl = [NSURL fileURLWithPath:filePath];
    NSLog(@"image URL: %@", [imageurl absoluteString]);
    
    Boolean allowClipping = ![options isEqualToString:@"*"];
    
    NSDictionary *curOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                
                                NSColor.blackColor,
                                NSWorkspaceDesktopImageFillColorKey,
                                
                                [NSNumber numberWithBool:allowClipping],
                                NSWorkspaceDesktopImageAllowClippingKey,
                                
                                [NSNumber numberWithInteger:NSImageScaleProportionallyUpOrDown],
                                NSWorkspaceDesktopImageScalingKey,
                                
                                nil];
    
	NSArray *screens = [NSScreen screens];
	for (NSScreen *curScreen in screens)
	{
        if (![[NSWorkspace sharedWorkspace] setDesktopImageURL: imageurl
                                            forScreen: curScreen
                                              options: curOptions
                                                error: &error])
        {
            [NSApp presentError:error];
        }
    }
}

- (void)enableLoginItemWithURL:(NSURL *)itemURL
{
	LSSharedFileListRef loginListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
	if (loginListRef) {
		// Insert the item at the bottom of Login Items list.
		LSSharedFileListItemRef loginItemRef = LSSharedFileListInsertItemURL(loginListRef,
                                                                             kLSSharedFileListItemLast,
                                                                             NULL,
                                                                             NULL,
                                                                             (CFURLRef)CFBridgingRetain(itemURL), 
                                                                             NULL, 
                                                                             NULL);		
		if (loginItemRef) {
			CFRelease(loginItemRef);
		}
		CFRelease(loginListRef);
	}
}


@end
