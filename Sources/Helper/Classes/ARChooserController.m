//
//  Chooser.m
//  Autorunner
//
//  Created by Dominik Pich on 2/14/11.
//  Copyright 2011 FHK Gummersbach. All rights reserved.
//

#import "ARChooserController.h"
#import "NSWindow+localize.h"
#import "M42PinchableTableview.h"
#import "NSUserDefaults+AR.h"

#define ARChooserControllerTextSizeMultiplier @"ARChooserControllerTextSizeMultiplier"

static NSArray *newEntriesForPath(NSString *path) {
	NSMutableArray *entries = [NSMutableArray arrayWithCapacity:2];
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	for (NSString *file in contents) {
		NSDictionary *entry = nil;
		
		if([[file lowercaseString] isEqualToString:@"autorun"] ||
		   [[[file stringByDeletingPathExtension] lowercaseString] rangeOfString:@"install"].location != NSNotFound ||
		   [[[file stringByDeletingPathExtension] lowercaseString] isEqualToString:@"driveunlock"] ||
		   [[[file stringByDeletingPathExtension] lowercaseString] isEqualToString:@"readme"] ||
		   [[[file pathExtension] lowercaseString] isEqualToString:@"html"]) {
			//skip invisibles
			if( [file characterAtIndex:0] == '.' )
				continue;
			
			//save entry
			NSString *cmd = [path stringByAppendingPathComponent:file];
			BOOL isDir = NO;
			NSString *title = nil;
			if([[NSFileManager defaultManager] fileExistsAtPath:cmd isDirectory:&isDir] && isDir && ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:cmd]) {
				title = [NSString stringWithFormat:NSLocalizedString(@"chooser_show_%@", @"chooser"), [[NSFileManager defaultManager] displayNameAtPath:cmd]];
			}
			else {
				title = [NSString stringWithFormat:NSLocalizedString(@"chooser_execute_%@", @"chooser"), [[NSFileManager defaultManager] displayNameAtPath:cmd]];
			}
			NSImage *icon = [workspace iconForFile:cmd];
			
			NSString *appName = nil, *type = nil;
			
			if([workspace getInfoForFile:cmd application:&appName type:&type] && appName != nil) {				
				entry = [NSDictionary dictionaryWithObjectsAndKeys:title, @"title",
						 cmd, @"command",
						 icon, @"icon",
						 nil];
			}			
		}
		
//		NSLog(@"%@, %@", file, fileName);
		if(entry) {
			[entries addObject:entry];
			NSLog(@"%@ -> entry", file);
		}
	}

	NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"chooser_showFolder", @"chooser"), @"title",
			 path, @"command",
		   path, @"path",
			 [workspace iconForFile:path], @"icon",
			 nil];
	[entries addObject:entry];

	entry = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"chooser_browseForCmd", @"chooser"), @"title",
						   @"browse", @"command",
							path, @"path",
						   [workspace iconForFile:@"/"], @"icon",
						   nil];
	[entries addObject:entry];
	
	entry = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"chooser_ignoreVolume", @"chooser"), @"title",
						   @"-", @"command",
							path, @"path",
							[NSImage imageNamed:@"icon_Ignore"], @"icon",
						   nil];
	[entries addObject:entry];
	
	return [entries copy];
}

@implementation ARChooserController

+ (NSArray*)entriesForPath:(NSString*)path {
	return [(newEntriesForPath(path)) autorelease];
}

+ (NSDictionary*)executeEntry:(NSDictionary*)entry andReturnCopy:(BOOL)flag commandRelativeTo:(NSString*)basePath {
	NSString *cmd = [entry objectForKey:@"command"];	
	BOOL relative = [[entry objectForKey:@"relative"] boolValue];	
	BOOL unstick = NO;
	NSImage *icon = nil;
	NSString *title = nil;
	if([cmd isEqualToString:@"browse"]) {
		NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
		[openPanel setDirectory:[entry objectForKey:@"path"]];
		[openPanel setCanChooseFiles:YES];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setAllowsMultipleSelection:NO];
		[openPanel setResolvesAliases:YES];

		if([openPanel runModal] == NSFileHandlingPanelOKButton) {		
			cmd = [[openPanel filenames] objectAtIndex:0];
			relative = NO;
		}
		else {
			cmd = nil; //ignore by setting it to NIL
			unstick = YES;
			relative = YES;
		}
	}
	else if([cmd isEqualToString:@"-"]) {
		cmd = nil; //ignore by setting it to NIL
		relative = YES;
		icon = [NSImage imageNamed:@"Icon_Ignore"];
		title = NSLocalizedString(@"chooser_ignoreVolume", @"chooser");
	}
	
	// execute
	if(cmd) {
		NSString * oldcmd = cmd; //save old
		if(relative)
			cmd = [basePath stringByAppendingPathComponent:cmd]; //prepend base path
		
		if(![[NSFileManager defaultManager] fileExistsAtPath:cmd]) //check if it maybe is NOT relative after all...
			cmd = oldcmd;
		
		if([[NSFileManager defaultManager] fileExistsAtPath:cmd]) //run and get icon 
		{
			[[NSWorkspace sharedWorkspace] openFile:cmd];
			icon = [[NSWorkspace sharedWorkspace] iconForFile:cmd];

			BOOL isDir = NO;
			if([[NSFileManager defaultManager] fileExistsAtPath:cmd isDirectory:&isDir] && isDir && ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:cmd]) {
				title = [NSString stringWithFormat:NSLocalizedString(@"chooser_show_%@", @"chooser"), [[NSFileManager defaultManager] displayNameAtPath:cmd]];
			}
			else {
				title = [NSString stringWithFormat:NSLocalizedString(@"chooser_execute_%@", @"chooser"), [[NSFileManager defaultManager] displayNameAtPath:cmd]];
			}
		}
	}

	if(flag) {
		entry = [[entry mutableCopy] autorelease];

		if(!relative) {
			if(cmd) {
				cmd = [cmd stringByReplacingOccurrencesOfString:basePath withString:@""];
				[(NSMutableDictionary*)entry setObject:[NSNumber numberWithBool:YES] forKey:@"relative"];
			}
		}
		
		[(NSMutableDictionary*)entry setObject:cmd ? cmd : @"-" forKey:@"command"];	
		
		if(title) {
			[(NSMutableDictionary*)entry setObject:title forKey:@"title"];
		}
		if(icon) {
			[(NSMutableDictionary*)entry setObject:icon forKey:@"icon"];
		}
		
		if(unstick) {
			[(NSMutableDictionary*)entry setObject:[NSNumber numberWithBool:NO] forKey:@"sticky"];
		}
		
		return entry;
	}
	return nil;
}


@synthesize path;
@synthesize delegate;
@synthesize userInfo;

- (id)initWithPath:(NSString*)p {
	self = [super initWithWindowNibName:@"Chooser"];
	if(self) {
		path = [p copy];
		entries = [[ARChooserController entriesForPath:path] retain];
	}
	return self;
}

- (void)dealloc {
	[path release];
	[entries release];
	[userInfo release];
	[super dealloc];
}

#pragma mark window

- (void)windowDidLoad {
	[entriesTable setDoubleAction:@selector(tableRowClicked:)];
	[[self window] localize];
	[[self window] setTitle:[NSString stringWithFormat:[[self window] title],[[NSFileManager defaultManager] displayNameAtPath:path]]];
}

- (IBAction)showWindow:(id)sender {
	[super showWindow:sender];

	[[self window] setRepresentedFilename:path];
	if([entriesTable respondsToSelector:@selector(setTextSizeMultiplier:)])
	{
		CGFloat f = [[NSUserDefaults arUserDefaults] floatForKey:ARChooserControllerTextSizeMultiplier];
		if(f < 0.1) f = 1;
		[(id)entriesTable setTextSizeMultiplier:f];
	}
}

- (void)windowWillClose:(NSNotification *)notification {
	if([entriesTable respondsToSelector:@selector(textSizeMultiplier)])
	{
		CGFloat f = [(id)entriesTable textSizeMultiplier];
		if(f < 0.1) f = 1;
		[[NSUserDefaults arUserDefaults] setFloat:f forKey:ARChooserControllerTextSizeMultiplier];
	}
}

#pragma mark actions

-(IBAction)tableRowClicked:(id)sender {
	[entriesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[entriesTable clickedRow]] byExtendingSelection:NO];
	[self okButtonPressed:nil];
}

-(IBAction)okButtonPressed:(id)sender {
	NSIndexSet *indexes = [entriesTable selectedRowIndexes];
	if(indexes.count==1) {
		NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithDictionary:[entries objectAtIndex:[indexes firstIndex]]];
//		[entry removeObjectForKey:@"icon"];
		[entry setObject:[NSNumber numberWithBool:([stickyCheckbox state] == NSOnState)] forKey:@"sticky"];
		[stickyCheckbox setState:NSOffState];
	
		[self close];
		[delegate chooser:self closedWithSelection:entry];
	}
}

-(IBAction)cancelButtonPressed:(id)sender {
	NSDictionary *ignoreEntry = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"chooser_ignoreVolume", @"chooser"), @"title",
			 @"-", @"command",
			 path, @"path",
			 [NSImage imageNamed:@"icon_Ignore"], @"icon",
			 nil];

	[self close];
	[delegate chooser:self closedWithSelection:ignoreEntry];
}

@end
