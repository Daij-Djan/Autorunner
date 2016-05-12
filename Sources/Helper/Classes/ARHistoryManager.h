//
//  History.h
//  Autorunner
//
//  Created by Dominik Pich on 2/15/11.
//  Copyright 2011 FHK Gummersbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ARHistoryManager : NSWindowController<NSWindowDelegate> {
	NSArray *actions;
	
	IBOutlet NSTableView *actionsTable;
	IBOutlet NSButton *forgetButton;
}
+ (ARHistoryManager*)sharedHistory;
+ (NSArray *)actionsFromDefaults;

- (NSDictionary *)matchingActionFromDefaultsForUUID:(NSString*)uuid;
- (void)saveAction:(NSDictionary*)action forUUID:(NSString*)uuid;
- (void)removeActionForUUID:(NSString*)uuid;

- (IBAction)forgetButtonPressed:(id)sender;

@end
