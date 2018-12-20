//This imports whatever classes I need
#import <UIKit/UIScrollView.h>
#import "SparkAppList.h"

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
NSMutableArray *appList = [[NSMutableArray alloc]init];
NSString *swipeAppId;
NSString *shouldKill;
BOOL playing = NO;
BOOL enabled;
BOOL easyFix;
BOOL appLock;
SBAppLayout *lay;

//Loads the Preferences settings
static void loadPrefs() {
	static NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.karimo299.dontkillmymusic"];
	enabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : NO;
	easyFix = [prefs objectForKey:@"EasyFix"] ? [[prefs objectForKey:@"EasyFix"] boolValue] : NO;
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
	if (playing && ![SparkAppList doesIdentifier:@"com.karimo299.dontkillmymusic" andKey:@"DisabledApps" containBundleIdentifier:nowPlayingAppID] && nowPlayingAppID) {
	nowPlayingAppID = [[self nowPlayingApplication] bundleIdentifier];
		NSLog(@"%@", nowPlayingAppID);
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
	} else if (appLock && [SparkAppList doesIdentifier:@"com.karimo299.dontkillmymusic" andKey:@"LockedApps" containBundleIdentifier:swipeAppId] && ![shouldKill isEqual:swipeAppId]) {
			[appList addObject:swipeAppId];
	}
	%orig;
	if (enabled) {
		lay = MSHookIvar <SBAppLayout*> (self,"_appLayout");
		[lay getAppId];
		if ([appList containsObject:swipeAppId]) {
			MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize = CGSizeMake(MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize.width,0);
		}
			// Support for SBCard by julioverne to prevent the home card to kill anything
	 	else if (([swipeAppId isEqual:@"com.apple.springboard"] && playing) || ([swipeAppId isEqual:@"com.apple.springboard"] && appList.count)) {
		MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize = CGSizeMake(MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize.width,0);
		}
	}
}

// This disables swiping down so EasySwitcherX by sparkdev_ will not run if music is playing
- (void)scrollViewDidScroll:(id)arg1 {
	if ((easyFix && playing && MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentOffset.y < 0) || (easyFix && appList.count && MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentOffset.y < 0) ) {
		MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize = CGSizeMake(MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize.width,0);
	} else {
		return %orig;
	}
}

//This checks if app card is held down to lock/unlock the appswitcher card
- (void)_handlePageViewTap:(id)arg1 {
	if (appLock) {
		if (MSHookIvar <UILongPressGestureRecognizer*>(self, "_enableKillAffordanceLongPressGestureRecognizer").state != 0) {
			%orig;
		} else {
			lay = MSHookIvar <SBAppLayout*> (self,"_appLayout");
			[lay getAppId];
			if (![appList containsObject:swipeAppId] && ![SparkAppList doesIdentifier:@"com.karimo299.dontkillmymusic" andKey:@"DisabledApps" containBundleIdentifier:swipeAppId]) {
				if ([SparkAppList doesIdentifier:@"com.karimo299.dontkillmymusic" andKey:@"LockedApps" containBundleIdentifier:swipeAppId]) {
					shouldKill = nil;
				}
				[appList addObject:swipeAppId];
			} else { 
				if ([SparkAppList doesIdentifier:@"com.karimo299.dontkillmymusic" andKey:@"LockedApps" containBundleIdentifier:swipeAppId]) {
					shouldKill = swipeAppId;
				}
				[appList removeObject:swipeAppId];
			}
		}
	} else {
		%orig;
	}
	[self layoutSubviews];
}
%end

%ctor {
    CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(), NULL,
		(CFNotificationCallback)loadPrefs,
		CFSTR("com.karimo299.dontkillmymusic/prefChanged"), NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPrefs();
}