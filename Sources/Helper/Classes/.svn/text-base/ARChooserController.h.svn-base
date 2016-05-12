//
//  Chooser.h
//  Autorunner
//
//  Created by Dominik Pich on 2/14/11.
//  Copyright 2011 FHK Gummersbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ARChooserController;

@protocol ARChooserDelegate

-(void)chooser:(ARChooserController*)chooser closedWithSelection:(NSDictionary*)entry;

@end

@interface ARChooserController : NSWindowController<NSWindowDelegate> {
	NSString *path;
	NSDictionary *userInfo;
	id<ARChooserDelegate> delegate;
	
	NSArray *entries; //dicts with name, command and icon

	IBOutlet NSTableView *entriesTable;
	IBOutlet NSButton *stickyCheckbox;
	IBOutlet NSButton *okButton;
	IBOutlet NSButton *cancelButton;
	
}
+ (NSArray*)entriesForPath:(NSString*)path;
+ (NSDictionary*)executeEntry:(NSDictionary*)entry andReturnCopy:(BOOL)flag commandRelativeTo:(NSString*)basePath;

- (id)initWithPath:(NSString*)p;

@property(readonly) NSString *path;
@property(retain) NSDictionary *userInfo;
@property(assign) id<ARChooserDelegate> delegate;

-(IBAction)okButtonPressed:(id)sender;
-(IBAction)cancelButtonPressed:(id)sender;

@end
