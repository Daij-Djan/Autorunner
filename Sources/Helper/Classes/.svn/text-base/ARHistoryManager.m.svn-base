//
//  History.m
//  Autorunner
//
//  Created by Dominik Pich on 2/15/11.
//  Copyright 2011 FHK Gummersbach. All rights reserved.
//

#import "ARHistoryManager.h"
#import "NSWindow+localize.h"
#import "M42PinchableTableview.h"
#import "NSUserDefaults+AR.h"

#define ARHistoryManagerTextSizeMultiplier @"ARHistoryManagerTextSizeMultiplier"

@implementation ARHistoryManager

+ (ARHistoryManager*)sharedHistory {
	static ARHistoryManager *history = nil;
	if(!history) {
		history = [[ARHistoryManager alloc] init];
	}
	return history;
}

+ (NSArray *)actionsFromDefaults {
	NSDictionary *actionsDict = [[NSUserDefaults arUserDefaults] dictionaryForKey:@"actions"];
	NSArray *uuids = [actionsDict allKeys];
	NSMutableArray *theActions = [NSMutableArray arrayWithCapacity:uuids.count];

	for (NSString *uuid in uuids) {
		NSMutableDictionary *dict = [[actionsDict objectForKey:uuid] mutableCopy];
		[dict setObject:uuid forKey:@"uuid"];
	
		NSString *path = [dict objectForKey:@"imagePath"];
		if(path) {
			NSImage *icon = [[NSImage alloc] initWithContentsOfFile:path];
			[dict setObject:icon forKey:@"icon"];
			[icon release];	
		}
		
//		NSLog(@"Got action %@ for %@", [dict objectForKey:@"command"], uuid);
		[theActions addObject:dict];
		[dict release];
	}
	
	return [NSArray arrayWithArray:theActions];
}

//---

- (void)refresh {
	[self willChangeValueForKey:@"actions"];
	[actions autorelease];
	actions = [[ARHistoryManager actionsFromDefaults] retain];
	[self didChangeValueForKey:@"actions"];	
}

- (NSDictionary *)matchingActionFromDefaultsForUUID:(NSString*)uuid {
	NSDictionary *entry = [[[NSUserDefaults arUserDefaults] dictionaryForKey:@"actions"] objectForKey:uuid];
	if(entry)
		NSLog(@"match for %@ is %@", uuid, [entry objectForKey:@"command"]);
	return entry;
}

- (void)saveAction:(NSDictionary*)action forUUID:(NSString*)uuid {
	NSMutableDictionary *theActions = [[[NSUserDefaults arUserDefaults] dictionaryForKey:@"actions"] mutableCopy];
	[theActions autorelease];

	if(!theActions) {
		theActions = [NSMutableDictionary dictionaryWithCapacity:1];
	}
	
	NSMutableDictionary *dict = [action mutableCopy];

	NSImage *icon = [dict objectForKey:@"icon"];
	if(icon) {
		NSString *finalPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		finalPath = [finalPath stringByAppendingPathComponent:@"Autorunner"];
		finalPath = [finalPath stringByAppendingPathComponent:@"Icons"];
		if(![[NSFileManager defaultManager] fileExistsAtPath:finalPath])
			[[NSFileManager defaultManager] createDirectoryAtPath:finalPath withIntermediateDirectories:YES attributes:nil error:nil];
		
		finalPath = [finalPath stringByAppendingPathComponent:uuid];
		NSData *data = [icon TIFFRepresentation];
		if([data writeToFile:finalPath atomically:YES])
			[dict setObject:finalPath forKey:@"imagePath"];
		
		[dict removeObjectForKey:@"icon"];
	}
	
	[theActions setObject:dict forKey:uuid];

	[dict release];
	
	[[NSUserDefaults arUserDefaults] setObject:theActions forKey:@"actions"];
	
	[self refresh];
}

- (void)removeActionForUUID:(NSString*)uuid {
	NSMutableDictionary *theActions = [[[NSUserDefaults arUserDefaults] dictionaryForKey:@"actions"] mutableCopy];
	[theActions autorelease];
	
	if(!theActions) {
		theActions = [NSMutableDictionary dictionaryWithCapacity:1];
	}
	
	[theActions removeObjectForKey:uuid];
	[[NSUserDefaults arUserDefaults] setObject:theActions forKey:@"actions"];
	
	[self refresh];
}

//---

- (id)init {
	self = [super initWithWindowNibName:@"History"];
	if(self) {
		[self refresh];
	}
	return self;
}

- (void)dealloc {
	[actions release];
	[super dealloc];
}

- (void)windowDidLoad {
	[[self window] localize];
}

- (IBAction)showWindow:(id)sender {
	[super showWindow:sender];

	if([actionsTable respondsToSelector:@selector(setTextSizeMultiplier:)])
	{
		CGFloat f = [[NSUserDefaults arUserDefaults] floatForKey:ARHistoryManagerTextSizeMultiplier];
		if(f < 0.1) f = 1;
		[(id)actionsTable setTextSizeMultiplier:f];
	}
}

- (void)windowWillClose:(NSNotification *)notification {
	if([actionsTable respondsToSelector:@selector(textSizeMultiplier)])
	{
		CGFloat f = [(id)actionsTable textSizeMultiplier];
		if(f < 0.1) f = 1; 
		[[NSUserDefaults arUserDefaults] setFloat:f forKey:ARHistoryManagerTextSizeMultiplier];
	}
}

- (IBAction)forgetButtonPressed:(id)sender {
#pragma unused(sender)
	NSIndexSet *indexes = [actionsTable selectedRowIndexes];
	if(indexes.count==1) {
		NSMutableDictionary *action = [NSMutableDictionary dictionaryWithDictionary:[actions objectAtIndex:[indexes firstIndex]]];
		[self removeActionForUUID:[action objectForKey:@"uuid"]];
		[self refresh];
	}
}

@end
