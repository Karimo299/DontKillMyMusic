//This imports whatever classes I need
#import <UIKit/UIScrollView.h>
#include <dlfcn.h>


@class SBApplication, SBAppLayout, UILongPressGestureRecognizer, UIScrollView;

@interface SBMediaController : NSObject
- (BOOL)isPlaying;
- (SBApplication *) nowPlayingApplication;
@end

@interface SBAppLayout : NSObject
- (void)getAppId;
@end

@interface SBFluidSwitcherItemContainer : UIView
- (void)layoutSubviews;
@end


//Gloabal variables I need
static NSUserDefaults *prefs;
NSMutableArray *appList = [[NSMutableArray alloc]init];
NSString *swipeAppId;
NSString *shouldKill;
BOOL playing = NO;
BOOL enabled;
BOOL appLock;
SBAppLayout *lay;

//Loads the Preferences settings
static void loadPrefs() {
	prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.karimo299.dontkillmymusic"];
	enabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;
	appLock = [prefs objectForKey:@"AppLock"] ? [[prefs objectForKey:@"AppLock"] boolValue] : YES;
	appList = NULL;
}

//Hooks into the class that controls the mediaplayer
//This is needed to check if there is any media playing atm and stroes it in a global var to use later
//It also stores the bundleId of the app that is playing
%hook SBMediaController
NSString *nowPlayingAppID;
- (void)_mediaRemoteNowPlayingApplicationIsPlayingDidChange:(id)arg1 {
	%orig;
	playing = [self isPlaying];
	nowPlayingAppID = [[self nowPlayingApplication] bundleIdentifier];
	if (playing && ![[prefs valueForKey:[NSString stringWithFormat:@"DisabledApps-%@", nowPlayingAppID]] boolValue] && nowPlayingAppID) {
		if (![appList containsObject:nowPlayingAppID]) {
			[appList addObject:nowPlayingAppID];
		}
	} else {
	[appList removeObject:nowPlayingAppID];
	nowPlayingAppID = nil;
	}
}
%end

//This hooks to the class that is used to identfy the appswitcher card
//This is needed to get the bundleId of the app in the appswitcher card
%hook SBAppLayout
%new
- (void)getAppId {
			NSDictionary *roles =  [self valueForKey:@"rolesToLayoutItemsMap"];
			NSArray *jsonArray = [roles allValues];
			NSDictionary *firstObjectDict = [jsonArray objectAtIndex:0];
			swipeAppId = [firstObjectDict valueForKey:@"displayIdentifier"];
	}
%end

//This is the class where the appswitcher is controlled
//Here I check if there is anything playing and compare the bundleId
%hook SBFluidSwitcherItemContainer
- (void)viewPresenting:(id)arg1 forTransitionRequest:(id)arg2 {
	%orig;
	shouldKill = nil;
}

- (void)layoutSubviews {
	[appList removeObject:shouldKill];
	if (nowPlayingAppID && ![appList containsObject:nowPlayingAppID] && ![shouldKill isEqual:nowPlayingAppID]) {
	[appList addObject:nowPlayingAppID];
	} else if (appLock && [[prefs valueForKey:[NSString stringWithFormat:@"LockedApps-%@", swipeAppId]] boolValue] && ![shouldKill isEqual:swipeAppId]) {
			[appList addObject:swipeAppId];
	}
	%orig;
	if (enabled) {
		lay = MSHookIvar <SBAppLayout*> (self,"_appLayout");
		[lay getAppId];
		if ([appList containsObject:swipeAppId]) {
			MSHookIvar <UIScrollView*> (self,"_verticalScrollView").scrollEnabled = NO;
		}
			// Support for SBCard by julioverne to prevent the home card to kill anything
	 	else if (([swipeAppId isEqual:@"com.apple.springboard"] && playing) || ([swipeAppId isEqual:@"com.apple.springboard"] && appList.count)) {
		MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize = CGSizeMake(MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize.width,0);
		} else {
			MSHookIvar <UIScrollView*> (self,"_verticalScrollView").scrollEnabled = YES;
		}
	}
}

// // This disables swiping down so EasySwitcherX by sparkdev_ will not run if music is playing
// - (void)scrollViewDidScroll:(id)arg1 {
// 	%orig;
// 	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/EasySwitcherX.dylib"] && playing && MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentOffset.y < 0) {
// 		// MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize = CGSizeMake(MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize.width,0);
//
// 	}
// }

//This checks if app card is held down to lock/unlock the appswitcher card
- (void)_handlePageViewTap:(id)arg1 {
	if (appLock) {
		if (MSHookIvar <UILongPressGestureRecognizer*>(self, "_selectionHighlightGestureRecognizer").state == 3) {
			lay = MSHookIvar <SBAppLayout*> (self,"_appLayout");
			[lay getAppId];
			if (![appList containsObject:swipeAppId] && ![[prefs valueForKey:[NSString stringWithFormat:@"DisabledApps-%@", swipeAppId]] boolValue]) {
				if ([[prefs valueForKey:[NSString stringWithFormat:@"LockedApps-%@", swipeAppId]] boolValue] || [swipeAppId isEqual:nowPlayingAppID]) {
					shouldKill = nil;
				}
				[appList addObject:swipeAppId];
			} else {
				if ([[prefs valueForKey:[NSString stringWithFormat:@"LockedApps-%@", swipeAppId]] boolValue] || [swipeAppId isEqual:nowPlayingAppID]) {
					shouldKill = swipeAppId;
				}
				[appList removeObject:swipeAppId];
			}
		} else {
			%orig;
		}
	} else {
		%orig;
	}
	[self layoutSubviews];
}
%end

%hook SparkSwitcherMenu
  -(void)requestKillAllApps {
		if ([appList count] == 0) %orig;
	}
%end

%ctor {
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/EasySwitcherX.dylib"]) {
		dlopen("/Library/MobileSubstrate/DynamicLibraries/EasySwitcherX.dylib", RTLD_LAZY);
	}
	%init;
    CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(), NULL,
		(CFNotificationCallback)loadPrefs,
		CFSTR("com.karimo299.dontkillmymusic/prefChanged"), NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPrefs();
}
