//
//  VolumeNotifier.h
//  HardwareGrowler
//
//  Created by Diggory Laycock on 10/02/2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//
#import <Foundation/Foundation.h>

@class ARVolumeNotifier;

@protocol ARVolumeNotifierDelegate

-(void) volumeNotifier:(ARVolumeNotifier*)notifier volumeDidMount:(NSDictionary*)info;
-(void) volumeNotifier:(ARVolumeNotifier*)notifier volumeDidUnmount:(NSDictionary*)info;

@end


@interface ARVolumeNotifier : NSObject {
	id<ARVolumeNotifierDelegate> delegate;
}

@property(assign) id<ARVolumeNotifierDelegate> delegate;

- (void)start;
- (void)stop;

+ (NSString*)makePath:(NSString*)path relativeToVolume:(NSDictionary*)info;
+ (NSDictionary*)volumeInfoDictWithPath:(NSString*)path;
+ (void)setVolumeInfoReferencePath:(NSString*)path forVolume:(NSDictionary*)info;

@end

extern NSString *kARVolumeNotifierFileCount;
extern NSString *kARVolumeNotifierReferenceFilePath;
extern NSString *kARVolumeNotifierReferenceFileMD5;
