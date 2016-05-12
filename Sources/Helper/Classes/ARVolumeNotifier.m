//
//  VolumeNotifier.c
//  HardwareGrowler
//
//  Created by Diggory Laycock on 10/02/2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "ARVolumeNotifier.h"
#import <sys/mount.h>
#import <DiskArbitration/DiskArbitration.h>
#import "NSFileManager+Count.h"
#import "md5.h"
#import "NSString+UUID.h"
#import "NSUserDefaults+AR.h"

NSString *kARVolumeNotifierFileCount = @"ARVolumeNotifierFileCount";
NSString *kARVolumeNotifierReferenceFilePath = @"ARVolumeNotifierReferenceFilePath";
NSString *kARVolumeNotifierReferenceFileMD5 = @"ARVolumeNotifierReferenceFileMD5";

#define kARVolumeNotifierUUID @"uuid"
#define kARVolumeNotifierVolumePath @"path"
#define kARVolumeNotifierDisksArray @"disks"

// wait 10 minutes for a corresponding did unmount notification
#define VolumeNotifierUnmountWaitSeconds	600.0

@implementation ARVolumeNotifier

+ (NSString*) volumeNameForPath:(NSString*)path {
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
	FSRef bundleRef;
	FSCatalogInfo info;
	HFSUniStr255 volName;
	
	if (url)
	{
		if (CFURLGetFSRef(url, &bundleRef))
		{
			if (FSGetCatalogInfo(&bundleRef, kFSCatInfoVolume, &info, NULL, NULL, NULL) == noErr)
			{
				if ( FSGetVolumeInfo ( info.volume, 0, NULL, kFSVolInfoNone, NULL, &volName, NULL) == noErr)
				{
					CFStringRef stringRef = FSCreateStringFromHFSUniStr(NULL, &volName);
					return [(NSString*)stringRef autorelease];
				}
			}
		}
	}
}

#pragma mark -

@synthesize delegate;

+ (NSDictionary*)volumeInfoDictWithPath:(NSString*)path {

	NSLog(@"--- volume info for %@ ---", path);
	
	NSString *diskUUID = nil;
	NSString *diskVolumeUUID = nil;
	NSNumber *diskSize = nil;
	NSString *diskVendor = nil;
	NSString *diskVolumeFormat = nil;
	NSNumber *diskWritable = nil;
	NSString *diskType = nil;
	//NSNumber *diskFileCount = nil;
	NSString *diskName = nil;
	NSURL *diskURL = nil;
	
	//get da description
	DADiskRef diskRef = 0;
	struct statfs buffer;
	statfs([path fileSystemRepresentation], &buffer);
	DASessionRef session = DASessionCreate( NULL );
	const char* bsdPath = buffer.f_mntfromname;
	DADiskRef dad = DADiskCreateFromBSDName( NULL, session, bsdPath);
	NSDictionary *diskDescription = (NSDictionary*)DADiskCopyDescription(dad);
	CFRelease(session);
	CFRelease(dad);
	
	//get info
	if(!diskDescription) {
		NSLog(@"No diskDescription from DA Disk");

		if([[path lowercaseString] rangeOfString:@"/volumes/"].location == NSNotFound) {
			NSLog(@"---skip mount not in volumes");
			return nil;
		}		
		
		diskName = [ARVolumeNotifier volumeNameForPath:path];
		diskURL = [NSURL fileURLWithPath:path];
	}
	else {
		//NSLog(@"collect description from DA Disk:\n%@", diskDescription);

		CFUUIDRef dUUID = (CFUUIDRef)[diskDescription objectForKey:(NSString*)kDADiskDescriptionMediaUUIDKey];//CFUUID
		diskUUID = dUUID ? (NSString*)CFUUIDCreateString(kCFAllocatorDefault, dUUID) : nil;
		[diskUUID autorelease];
		
		CFUUIDRef dvUUID = (CFUUIDRef)[diskDescription objectForKey:(NSString*)kDADiskDescriptionVolumeUUIDKey];//CFUUID
		diskVolumeUUID = dvUUID ? (NSString*)CFUUIDCreateString(kCFAllocatorDefault, dvUUID) : nil;
		[diskVolumeUUID autorelease];
		
		diskSize = [diskDescription objectForKey:(NSString*)kDADiskDescriptionMediaSizeKey];
		diskVendor = [diskDescription objectForKey:(NSString*)kDADiskDescriptionDeviceVendorKey];
		diskVolumeFormat = [diskDescription objectForKey:(NSString*)kDADiskDescriptionVolumeKindKey];
		diskWritable = [diskDescription objectForKey:(NSString*)kDADiskDescriptionMediaWritableKey];
		diskType = [diskDescription objectForKey:(NSString*)kDADiskDescriptionMediaTypeKey];
		//diskFileCount = [NSNumber numberWithInt:[[NSFileManager defaultManager] countOfFilesInDirectory:path]];
		diskName = [diskDescription objectForKey:(NSString*)kDADiskDescriptionVolumeNameKey];
		diskURL = [diskDescription objectForKey:(NSString*)kDADiskDescriptionVolumePathKey];

		[diskDescription autorelease];
	}
	
	//-----
	
	if([diskVolumeFormat isEqualToString:@"cddafs"]) {
		NSLog(@"---skip audo cd");
		return nil;
	}
	else if([diskVolumeFormat isEqualToString:@"udf"]) {
		NSString *thisMountPath = [diskURL path];
		if(!thisMountPath) thisMountPath = path;		
		
		NSString *newReferenceFilePath = [thisMountPath stringByAppendingPathComponent:@"VIDEO_TS"];
		if([[NSFileManager defaultManager] fileExistsAtPath:newReferenceFilePath]) {
			NSLog(@"---skip video dvd");
			return nil;
		}
	}
		
	//-----
	
	NSLog(@"compare description to saved disks");
	NSDictionary *disks = [[NSUserDefaults arUserDefaults] dictionaryForKey:kARVolumeNotifierDisksArray];
	NSString *uuid = nil;
	
	CFUUIDRef tUUID;
	NSString *savedUUID;
	NSString *tempString;	
	NSNumber *tempNumber;	
	
	for (NSDictionary *savedDiskDescription in [disks allValues]) {
		//NSLog(@"+++\nmatch against:\n%@", savedDiskDescription);
		
		savedUUID = [savedDiskDescription objectForKey:kARVolumeNotifierUUID];
		
		if(diskVolumeUUID ) {
			if(savedUUID && [diskVolumeUUID isEqualToString:savedUUID]) {
				NSLog(@"perfect match per volume UUID");
				uuid = diskVolumeUUID;
				break;
			}
		}

		//no uuid, fallback
		//NSLog(@"- no uuid, fallback");
		
		if(diskVendor) {
			tempString = [savedDiskDescription objectForKey:(NSString*)kDADiskDescriptionDeviceVendorKey];
			if(!tempString || ![diskVendor isEqualToString:tempString]) {
				//NSLog(@"vendor doesnt match");
				continue;
			 }
		}
			
		if(diskSize) {
			tempNumber = [savedDiskDescription objectForKey:(NSString*)kDADiskDescriptionMediaSizeKey];
			if(!tempNumber || ![diskSize isEqualToNumber:tempNumber]) {
				//NSLog(@"disk size doesnt match");
				continue;
			}
		}

		if(diskVolumeFormat) {
			tempString = [savedDiskDescription objectForKey:(NSString*)kDADiskDescriptionVolumeKindKey];
			if(!tempString || ![diskVolumeFormat isEqualToString:tempString]) {
				//NSLog(@"volume format doesnt match");
				continue;
			}
		}
		
		if(diskWritable) {
			tempNumber = [savedDiskDescription objectForKey:(NSString*)kDADiskDescriptionMediaWritableKey];
			if(!tempNumber || [diskWritable boolValue] != [tempNumber boolValue]) {
				//NSLog(@"the writable flag doesnt match");
				continue;
			}
		}
		
		if(diskType) {
			tempString = [savedDiskDescription objectForKey:(NSString*)kDADiskDescriptionMediaTypeKey];
			if(!tempString || ![diskType isEqualToString:tempString] ) {
				//NSLog(@"disk types dont match");
				continue;
			}
		}
		
		//check reference file if we have any!!!
		NSString *savedReferenceFile = [savedDiskDescription objectForKey:kARVolumeNotifierReferenceFilePath];
		if(savedReferenceFile) {
			//NSLog(@"! check reference file %@", savedReferenceFile);
			
			NSString *thisMountPath = [diskURL path];
			if(!thisMountPath) thisMountPath = path;		

			NSString *newReferenceFilePath = [thisMountPath stringByAppendingPathComponent:savedReferenceFile];
			if(![[NSFileManager defaultManager] fileExistsAtPath:newReferenceFilePath]) {
				//NSLog(@"not our disk OR no longer has what we want");
				continue; 
				
			}

			NSString *savedMD5 = [savedDiskDescription objectForKey:kARVolumeNotifierReferenceFilePath];
			if (savedMD5) {
				NSString *newMD5 = md5(newReferenceFilePath);
				if([savedMD5 isEqualToString:newMD5]) {
					NSLog(@"since the reference files match 100%%, we are willing to call this a match");
					uuid = savedUUID ? savedUUID : [[disks allKeysForObject:savedDiskDescription] objectAtIndex:0];
					break;
				}
			}
		}		

		//last resort: guess by name
		if(diskName) {
			tempString = [savedDiskDescription objectForKey:(NSString*)kDADiskDescriptionVolumeNameKey];
			if(!tempString || ![diskName isEqualToString:tempString]) {
				//NSLog(@"name differs and given that we have no UUIDs, this is fatal :D");
				continue;
			}
		}

		if(diskUUID) {
			tempString = [savedDiskDescription objectForKey:(NSString*)kDADiskDescriptionMediaUUIDKey];//!String
			if(!tempString || ![diskUUID isEqualToString:tempString]) {
				//NSLog(@"media UUIDs didnt matched");
				continue;
			}
		}
		
		/*found our internal UUID*/
		uuid = savedUUID ? savedUUID : [[disks allKeysForObject:savedDiskDescription] objectAtIndex:0];
		break;
	}
	
	if(!uuid) {
		uuid = diskVolumeUUID ? diskVolumeUUID : [NSString stringWithUUID:NULL];
		NSLog(@"new uuid %@ for %@", uuid, path);
		
		//save it to defaults
		NSMutableDictionary *disksM = disks ? [disks mutableCopy] : [[NSMutableDictionary alloc] initWithCapacity:1];
		NSMutableDictionary *diskDescriptionM = [NSMutableDictionary dictionaryWithCapacity:10];
		
		if(diskVolumeUUID) [diskDescriptionM setObject:diskVolumeUUID forKey:kARVolumeNotifierUUID];
		if(diskUUID) [diskDescriptionM setObject:diskUUID forKey:(NSString*)kDADiskDescriptionMediaUUIDKey];
		if(diskSize) [diskDescriptionM setObject:diskSize forKey:(NSString*)kDADiskDescriptionMediaSizeKey];
		if(diskVendor) [diskDescriptionM setObject:diskVendor forKey:(NSString*)kDADiskDescriptionDeviceVendorKey];
		if(diskVolumeFormat) [diskDescriptionM setObject:diskVolumeFormat forKey:(NSString*)kDADiskDescriptionVolumeKindKey];
		if(diskWritable) [diskDescriptionM setObject:diskWritable forKey:(NSString*)kDADiskDescriptionMediaWritableKey];
		if(diskType) [diskDescriptionM setObject:diskType forKey:(NSString*)kDADiskDescriptionMediaTypeKey];
		//if(diskFileCount) [diskDescriptionM setObject:diskFileCount forKey:kARVolumeNotifierFileCount];
		if(diskName) [diskDescriptionM setObject:diskName forKey:(NSString*)kDADiskDescriptionVolumeNameKey];
		if(diskURL) [diskDescriptionM setObject:[diskURL path] forKey:kARVolumeNotifierVolumePath];//?
		
		[disksM setObject:diskDescriptionM forKey:uuid];
		[[NSUserDefaults arUserDefaults] setObject:disksM forKey:kARVolumeNotifierDisksArray];
		[disksM release];
//		[diskDescriptionM release];
	}
	else {
		NSLog(@"found disk with uuid %@", uuid);
	}
	
	//get runtime entry 
	NSString *name = diskName;
	NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[diskURL path]];
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[diskURL path], kARVolumeNotifierVolumePath, 
						  name, @"name", 
						  uuid, kARVolumeNotifierUUID,
						  icon, @"icon", nil];
	return info;
}

+ (NSString*)makePath:(NSString*)path relativeToVolume:(NSDictionary*)info {
	NSString *basePath = [info objectForKey:kARVolumeNotifierVolumePath];

	if([path rangeOfString:basePath].location == NSNotFound) {
		NSLog(@"Cannot make relative path: %@ for volume: %@", path, info);
		return nil;
	}
	
	return [path stringByReplacingOccurrencesOfString:basePath withString:@""];
}

+ (void)setVolumeInfoReferencePath:(NSString*)path forVolume:(NSDictionary*)info {
	if([path isEqualToString:@"/"]) {
		NSLog(@"Ignore reference for root");
		return;
	}

	NSString *basePath = [info objectForKey:kARVolumeNotifierVolumePath];
	NSString *realpath = [basePath stringByAppendingPathComponent:path];
	
	//check for existance
	if(![[NSFileManager defaultManager] fileExistsAtPath:realpath]) {
		NSLog(@"Cannot use path: %@ as reference path for volume: %@", path, info);
		return;
	}
	
	//md5
	NSString *md5sum = md5(realpath);
	
	//get uuid for volume
	NSString *uuid = [info objectForKey:kARVolumeNotifierUUID];
	NSLog(@"set reference for %@ to %@", path, uuid);
	
	//get saved array
	NSMutableDictionary *disksM = [[[NSUserDefaults arUserDefaults] dictionaryForKey:kARVolumeNotifierDisksArray] mutableCopy];
	NSMutableDictionary *diskDescriptionM = [[disksM objectForKey:uuid] mutableCopy];
	
	//set reference info
	[diskDescriptionM setObject:path forKey:kARVolumeNotifierReferenceFilePath];
	[diskDescriptionM setObject:md5sum forKey:kARVolumeNotifierReferenceFileMD5];
	
	//save
	[disksM setObject:diskDescriptionM forKey:uuid];
	[diskDescriptionM release];
	[[NSUserDefaults arUserDefaults] setObject:disksM forKey:kARVolumeNotifierDisksArray];
	[disksM release];
}

#pragma mark -

+ (void)updateVolumeWithOldPath:(NSString*)path andOldLabel:(NSString*)old withNewPath:(NSString*)newpath andNewLabel:(NSString*)new {
	NSDictionary *disks = [[NSUserDefaults arUserDefaults] dictionaryForKey:kARVolumeNotifierDisksArray];
	NSMutableDictionary *diskDescriptionM = nil;
	NSString *uuid = nil;
	
	for(NSDictionary *diskDescription in [disks allValues]) {
		if([[diskDescription objectForKey:kARVolumeNotifierVolumePath] isEqualToString:path] &&
		   [[diskDescription objectForKey:(NSString*)kDADiskDescriptionVolumeNameKey] isEqualToString:old]) {
			NSLog(@"update %@", diskDescription);
			diskDescriptionM = [[diskDescription mutableCopy] autorelease];
			uuid = [[disks allKeysForObject:diskDescription] objectAtIndex:0];
		}
	}
	
	if(uuid) {
		[diskDescriptionM setObject:new forKey:(NSString*)kDADiskDescriptionVolumeNameKey];
		[diskDescriptionM setObject:newpath forKey:kARVolumeNotifierVolumePath];
		NSMutableDictionary *disksM = [disks mutableCopy];
		[disksM setObject:diskDescriptionM forKey:uuid];
		[[NSUserDefaults arUserDefaults] setObject:disksM forKey:kARVolumeNotifierDisksArray];
		[disksM release];
		 
	}
}

#pragma mark -

- (void)dealloc {
	[self stop];
	[super dealloc];
}

- (void)start {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSNotificationCenter *center = [workspace notificationCenter];
	
	[center addObserver:self selector:@selector(volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];
	[center addObserver:self selector:@selector(volumeDidRename:) name:NSWorkspaceDidRenameVolumeNotification object:nil];
	[center addObserver:self selector:@selector(volumeDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
}

- (void)stop {
	NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
	[center removeObserver:self];
}

#pragma mark volume notifications

- (void) volumeDidMount:(NSNotification *)aNotification {
	NSString *path = [[aNotification userInfo] objectForKey:@"NSDevicePath"];
	NSDictionary *dict = [ARVolumeNotifier volumeInfoDictWithPath:path];
	if(dict)
		[delegate volumeNotifier:self volumeDidMount:dict];
}

- (void) volumeDidRename:(NSNotification *)aNotification {
	NSString *oldpath = [[[aNotification userInfo] objectForKey:@"NSWorkspaceVolumeOldURLKey"] path];
	NSString *old = [[aNotification userInfo] objectForKey:@"NSWorkspaceVolumeOldLocalizedNameKey"];
	NSString *newpath = [[[aNotification userInfo] objectForKey:@"NSWorkspaceVolumeURLKey"] path];
	NSString *new = [[aNotification userInfo] objectForKey:@"NSWorkspaceVolumeLocalizedNameKey"];
	[ARVolumeNotifier updateVolumeWithOldPath:oldpath andOldLabel:old withNewPath:newpath andNewLabel:new];
}

- (void) volumeDidUnmount:(NSNotification *)aNotification {
	NSString *path = [[aNotification userInfo] objectForKey:@"NSDevicePath"];
	NSDictionary *dict = [NSDictionary dictionaryWithObject:path forKey:kARVolumeNotifierVolumePath];
	[delegate volumeNotifier:self volumeDidUnmount:dict];
}

@end
