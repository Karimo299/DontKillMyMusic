//This imports whatever classes I need
#import <UIKit/UIScrollView.h>

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
NSMutableArray *otherApps = [[NSMutableArray alloc]init];
NSString *playingAppId;
NSString *swipeAppId;
int shouldKill = 1;
int isDefaultLocked;
int playing = 0;
BOOL enabled;
BOOL easyFix;
BOOL appLock;
BOOL higlight;
SBAppLayout *lay;

//Loads the Preferences settings
static void loadPrefs() {
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.karimo299.dontkillmymusic.plist"];
	enabled = [[prefs valueForKey:@"isEnabled"] boolValue];
	easyFix = [[prefs valueForKey:@"EasyFix"] boolValue];
	appLock = [[prefs valueForKey:@"AppLock"] boolValue];
 	higlight = [[prefs valueForKey:@"higlight"] boolValue];
	isDefaultLocked = [[prefs valueForKey:[NSString stringWithFormat:@"EnabledApps-%@", swipeAppId]] boolValue];
}

//Hooks into the class that controls the mediaplayer
//This is needed to check if there is any media playing atm and stroes it in a global var to use later
//It also stores the bundleId of the app that is playing
%hook SBMediaController
- (void)_mediaRemoteNowPlayingApplicationIsPlayingDidChange:(id)arg1 {
	loadPrefs();
	%orig;
	playingAppId = [[self nowPlayingApplication] bundleIdentifier];
	playing = [self isPlaying];

		if (!playing) {
			playingAppId = @"";
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
- (void)layoutSubviews {
	loadPrefs();
	if (isDefaultLocked && appLock) {
			[otherApps addObject:swipeAppId];
			if (!shouldKill) {
			[otherApps removeObject:swipeAppId];
		}
	}
	%orig;
	if (enabled) {
		lay = MSHookIvar <SBAppLayout*> (self,"_appLayout");
		[lay getAppId];
		if ([otherApps containsObject:swipeAppId] || [playingAppId isEqual:swipeAppId]) {
			MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize = CGSizeMake(MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize.width,0);
		}
			// Support for SBCard by julioverne to prevent the home card to kill anything
	 	else if (([swipeAppId isEqual:@"com.apple.springboard"] && playing) || ([swipeAppId isEqual:@"com.apple.springboard"] && otherApps.count)) {
		MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize = CGSizeMake(MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize.width,0);
		}
	}
}

// This disables swiping down so EasySwitcherX by sparkdev_ will not run if music is playing
- (void)scrollViewDidScroll:(id)arg1 {
	if (MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentOffset.y > 200) {
		shouldKill = 1;
	}
	if ((easyFix && playing && MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentOffset.y < 0) || (easyFix && otherApps.count && MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentOffset.y < 0) ) {
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
			if (![otherApps containsObject:swipeAppId] && ![swipeAppId isEqual:playingAppId]) {
				[otherApps addObject:swipeAppId];
			} else {
				shouldKill = 0;
				[otherApps removeObject:swipeAppId];
			}
		}
	} else {
		%orig;
	}
	[self layoutSubviews];
}
%end
