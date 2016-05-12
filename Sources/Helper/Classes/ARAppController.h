#import <Cocoa/Cocoa.h>
#import "ARVolumeNotifier.h"
#import "ARChooserController.h"

@class ARHistoryManager;

@interface ARAppController : NSObject<ARVolumeNotifierDelegate, ARChooserDelegate> {
	ARVolumeNotifier *notifier;
	
	NSStatusItem *item;
	NSMenu *menu;
	
	NSMutableArray *choosers;
	ARHistoryManager *history;
}

@end
