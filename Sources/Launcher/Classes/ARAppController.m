//
//  ARAppController.m
//  Autorunner
//
//  Created by Dominik Pich on 3/15/11.
//  Copyright 2011 FHK Gummersbach. All rights reserved.
//

#import "ARAppController.h"
#import <ServiceManagement/SMLoginItem.h>
#import "NSWindow+localize.h"
#import "M42PinchableWebView.h"
#import "NSUserDefaults+AR.h"

#define ARAboutControllerTextSizeMultiplier @"ARAboutControllerTextSizeMultiplier"

#define ARAppControllerEnabled @"ARAppControllerEnabled"
#define ARAppControllerAlreadyLaunched @"ARAppControllerAlreadyLaunched"

@implementation ARAppController

- (NSBundle*)getRegisteredHelper {
	NSString *childBundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Library/LoginItems/AutorunnerHelper.app"];
	NSBundle *childBundle = [NSBundle bundleWithPath:childBundlePath];
	if(LSRegisterURL((CFURLRef)[childBundle bundleURL], YES) != noErr) {
		NSLog(@"Failed to register helper");
	}
	
	return childBundle;
}

#pragma mark window

- (void)windowDidLoad {
	BOOL run = [[NSUserDefaults arUserDefaults] boolForKey:ARAppControllerEnabled];
	[checkbox setState:run ? NSOnState : NSOffState];
	NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"Html"];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
	[[webview mainFrame] loadRequest:request];
	[window localize];
	
}

- (IBAction)showWindow:(id)sender {	
	if([webview respondsToSelector:@selector(setTextSizeMultiplier:)])
	{
		CGFloat f = [[NSUserDefaults arUserDefaults] floatForKey:ARAboutControllerTextSizeMultiplier];
		if(f < 0.1) f = 1;
		[(id)webview setTextSizeMultiplier:f];
	}

	[window makeKeyAndOrderFront:sender];
	if(!alreadyDone) {
		alreadyDone = YES;
		[self windowDidLoad];
	}
	
	for (NSView *view in [[window contentView] subviews]) {
		if([view isKindOfClass:[NSTabView class]]) {
			[(NSTabView*)view selectTabViewItemAtIndex:0];
		}
	}
}

- (void)windowWillClose:(NSNotification *)notification {
	if([webview respondsToSelector:@selector(textSizeMultiplier)])
	{
		CGFloat f = [(id)webview textSizeMultiplier];
		if(!f) f = 1;
		if(f < 0.1) f = 1;
		[[NSUserDefaults arUserDefaults] setFloat:f forKey:ARAboutControllerTextSizeMultiplier];
	}
}

#pragma mark preferences

- (IBAction)toggleRunAtLogin:(id)sender {
	BOOL orun = [[NSUserDefaults arUserDefaults] boolForKey:ARAppControllerEnabled];
	BOOL run = !orun; //toggle
	
	//done on quit.. force quitting is bad ;)
//	NSBundle *childBundle = [self getRegisteredHelper];	
//	SMLoginItemSetEnabled((CFStringRef)[childBundle bundleIdentifier], run);
	
	[[NSUserDefaults arUserDefaults] setBool:run forKey:ARAppControllerEnabled];
}

#pragma mark application
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	[NSBundle loadNibNamed:@"MainMenu" owner:self];
	NSBundle *childBundle = [self getRegisteredHelper];
	
	if(![[NSUserDefaults arUserDefaults] boolForKey:ARAppControllerAlreadyLaunched]) {
		[[NSUserDefaults arUserDefaults] setBool:YES forKey:ARAppControllerAlreadyLaunched];
		[[NSUserDefaults arUserDefaults] setBool:NO forKey:ARAppControllerEnabled];		
	}
	SMLoginItemSetEnabled((CFStringRef)[childBundle bundleIdentifier], NO);
	SMLoginItemSetEnabled((CFStringRef)[childBundle bundleIdentifier], YES);			
	
	[self showWindow:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	BOOL run = [[NSUserDefaults arUserDefaults] boolForKey:ARAppControllerEnabled];
	if(!run) {
		NSString *message = @"Continue Autorunner in background and start it on login";
		NSString *information = @"Run in Background and Auto-Start on Login? (Autorunner shows no dock icon when run that way)";
		NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:information];
		[alert setAlertStyle:NSWarningAlertStyle];
		int result = [alert runModal];
		if( result == NSAlertDefaultReturn )
		{
			[[NSUserDefaults arUserDefaults] setBool:YES forKey:ARAppControllerEnabled];
			return;
		}

		NSBundle *childBundle = [self getRegisteredHelper];
		SMLoginItemSetEnabled((CFStringRef)[childBundle bundleIdentifier], NO);			
	}
}

@end
