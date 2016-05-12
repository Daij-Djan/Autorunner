//
//  ARAboutController.m
//  Autorunner
//
//  Created by Dominik Pich on 3/10/11.
//  Copyright 2011 FHK Gummersbach. All rights reserved.
//

#import "ARAboutController.h"
#import "NSWindow+localize.h"
#import "M42PinchableWebView.h"
#import "NSUserDefaults+AR.h"

#define ARAboutControllerTextSizeMultiplier @"ARAboutControllerTextSizeMultiplier"

@implementation ARAboutController

+ (id)sharedAbout {
	static ARAboutController *about = nil;
	if(!about) {
		about = [[ARAboutController alloc] init];
	}
	return about;
}

- (id)init {
	return [super initWithWindowNibName:@"About"];
}

- (void)windowDidLoad {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"Html"];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
	[[webView mainFrame] loadRequest:request];
	[[self window] localize];
}

- (IBAction)showWindow:(id)sender {
	[super showWindow:sender];

	if([webView respondsToSelector:@selector(setTextSizeMultiplier:)])
	{
		CGFloat f = [[NSUserDefaults arUserDefaults] floatForKey:ARAboutControllerTextSizeMultiplier];
		if(f < 0.1) f = 1;
		[(id)webView setTextSizeMultiplier:f];
	}
}

- (void)windowWillClose:(NSNotification *)notification {
	if([webView respondsToSelector:@selector(textSizeMultiplier)])
	{
		CGFloat f = [(id)webView textSizeMultiplier];
		if(!f) f = 1;
		if(f < 0.1) f = 1;
		[[NSUserDefaults arUserDefaults] setFloat:f forKey:ARAboutControllerTextSizeMultiplier];
	}
}

@end
