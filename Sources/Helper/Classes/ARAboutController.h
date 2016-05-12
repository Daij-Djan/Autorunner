//
//  ARAboutController.h
//  Autorunner
//
//  Created by Dominik Pich on 3/10/11.
//  Copyright 2011 FHK Gummersbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface ARAboutController : NSWindowController<NSWindowDelegate> {
	IBOutlet WebView *webView;
}

+ (id)sharedAbout;

@end
