#import "ARAppController.h"

#import "ARVolumeNotifier.h"

#import "ARChooserController.h"
#import "ARHistoryManager.h"
#import "ARAboutController.h"

#import "KFAppleScriptHandlerAdditionsCore.h"

@implementation ARAppController

- (IBAction)about:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[[ARAboutController sharedAbout] showWindow:sender];
	[NSApp activateIgnoringOtherApps:YES];	
}

- (IBAction)history:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[[ARHistoryManager sharedHistory] showWindow:sender];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)quit:(id)sender {
	NSRunInformationalAlertPanel(@"How to quit Autorunner", @"This is the Autorunner helper app. Go to the Autorunner main application via your Dock and uncheck 'Start automatically at login (Autorunner shows no dock icon when run in background that way)'", @"OK", nil, nil);
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
#pragma unused(notification)
	notifier = [[ARVolumeNotifier alloc] init];
	notifier.delegate = self;
	[notifier start];
	
	BOOL isRunAtLogin = NO;
	
	menu = [[NSMenu alloc] init];
	[menu addItemWithTitle:NSLocalizedString(@"menu_SavedActions", @"menu") action:@selector(history:) keyEquivalent:@","];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:NSLocalizedString(@"menu_About", @"menu") action:@selector(about:) keyEquivalent:@"a"];
	[menu addItemWithTitle:NSLocalizedString(@"menu_Quit", @"menu") action:@selector(quit:) keyEquivalent:@"q"];
	
	item = [[[NSStatusBar systemStatusBar] statusItemWithLength:[[NSStatusBar systemStatusBar] thickness]] retain];
	[item setImage:[NSImage imageNamed:@"icon_Menubar"]];
	[item setMenu:menu];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
#pragma unused(notification)
	[notifier release];
	[item release];
	[menu release];

	for (ARChooserController *chooser in choosers) {
		chooser.delegate = nil;
		[chooser close];
//		[chooser release];
	}
	[choosers release];
}

#pragma mark VolumeNotifierDelegate

-(void) volumeNotifier:(ARVolumeNotifier*)notifier volumeDidMount:(NSDictionary*)info {
#pragma unused(notifier)
	[self performSelector:@selector(delayedDidMount:) withObject:info afterDelay:1.0];
}
- (void)delayedDidMount:(NSDictionary*)info {
	//sticky? or chooser
	NSString *uuid = [info objectForKey:@"uuid"];	
	NSDictionary *entry = [[ARHistoryManager sharedHistory] matchingActionFromDefaultsForUUID:uuid];
	BOOL closeFinderWindow = NO;
	BOOL needsChooser = NO;
	
	//check if have saved entry we can execute
	if(entry != nil) {
		//run
		NSString *basePath = [info objectForKey:@"path"];
		[ARChooserController executeEntry:entry andReturnCopy:NO commandRelativeTo:basePath];

		NSString *cmd = [entry objectForKey:@"command"];		
		closeFinderWindow = ![cmd isEqualToString:@"/"];
	}
	else 
	{
		//we have no saved action, close finder window and show chooser
		needsChooser = YES;
		closeFinderWindow = YES;
	}

	//call applescript to close volume window if it is about to open or cmd is ignore
	if(closeFinderWindow) {
		NSURL *url = [[NSBundle mainBundle] URLForResource:@"closeFinderWindow" withExtension:@"scpt"];
		if(url) {
			NSDictionary *errorDict = nil;
			NSAppleScript *as = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errorDict];
			if(as && !errorDict) {
				NSString *name = [info objectForKey:@"name"];
				[as executeHandler:@"close_finder_window" error:&errorDict withParameter:name];
				[as release];
			}
			if(errorDict) {
				NSLog(@"Failed to execute handler: %@", errorDict);
			}
		}
	}

	//open our chooser if needed
	if(needsChooser) {
		ARChooserController *chooser = [[ARChooserController alloc] initWithPath:[info objectForKey:@"path"]];
		chooser.userInfo = info;
		chooser.delegate = self;
		[NSApp activateIgnoringOtherApps:YES];
		[chooser showWindow:nil];
		NSLog(@"showWindow of chooser with path: %@", [info objectForKey:@"path"]);
		
		if(!choosers)
			choosers = [[NSMutableArray alloc] initWithCapacity:1];
		[choosers addObject:chooser];
		[chooser release];		
	}
}

-(void) volumeNotifier:(ARVolumeNotifier*)notifier volumeDidUnmount:(NSDictionary*)info {
#pragma unused(notifier)
	ARChooserController *chooserToDelete = nil;
	
	for (ARChooserController *chooser in choosers) {
		if([chooser.path isEqualToString:[info objectForKey:@"path"]]) {
			chooserToDelete = chooser;
			break;
		}
	}
	
	if(chooserToDelete) {
		chooserToDelete.delegate = nil;
		[chooserToDelete close];
		NSLog(@"close matching chooser: %@", [info objectForKey:@"path"]);
		[choosers removeObject:chooserToDelete];
//		[chooserToDelete release];
	}
}

#pragma mark ChooserDelegate

-(void)chooser:(ARChooserController*)chooser closedWithSelection:(NSDictionary*)entry {
	if(entry) {
		//run
		NSDictionary *info = chooser.userInfo;
		NSString *basePath = [info objectForKey:@"path"];
		entry = [ARChooserController executeEntry:entry andReturnCopy:YES commandRelativeTo:basePath];
		
		//save in history if sticky
		if([[entry objectForKey:@"sticky"] boolValue]) {
			NSString *uuid = [info objectForKey:@"uuid"];
			BOOL relative = [[entry objectForKey:@"relative"] boolValue];
			NSString *command = [entry objectForKey:@"command"];
			
			//save reference if relative
			if(relative) {
				[ARVolumeNotifier setVolumeInfoReferencePath:command forVolume:info];
			}

			//add volume to dictionary -> for display
			NSMutableDictionary *mentry = [[entry mutableCopy] autorelease];
			[mentry setObject:[info objectForKey:@"name"] forKey:@"volume"];

			//save
			[[ARHistoryManager sharedHistory] saveAction:mentry forUUID:uuid];			
		}
	}
	[choosers removeObject:chooser];
}

@end
