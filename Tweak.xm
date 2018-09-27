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

// NSDictionary for the values from the Preferences page
NSDictionary *values = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.karimo299.dontkillmymusic"];

// Sets a bool if enabled switch is on
BOOL enabled = [[values valueForKey:@"isEnabled"] isEqual:@1];
BOOL easyFix = [[values valueForKey:@"EasyFix"] isEqual:@1];

//Gloabal variables I need
NSString *playingAppId;
NSString *swipeAppId;
int playing = 0;

//Hooks into the class that controls the mediaplayer
//This is needed to check if there is any media playing atm and stroes it in a global var to use later
//It also stores the bundleId of the app that is playing
%hook SBMediaController
-(void)_mediaRemoteNowPlayingApplicationIsPlayingDidChange:(id)arg1 {
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
-(void)layoutSubviews {
	%orig;
	if (enabled) {
		SBAppLayout* lay = MSHookIvar <SBAppLayout*> (self,"_appLayout");
		[lay getAppId];
		if ([swipeAppId isEqual:playingAppId]) {
			MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize = CGSizeMake(MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize.width,0);
		}
		// Support for SBCard by julioverne to prevent the home card to kill anything
		else if (playing && [swipeAppId isEqual:@"com.apple.springboard"]) {
			MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize = CGSizeMake(MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize.width,0);
		}
	}
}

-(void)scrollViewDidScroll:(id)arg1 {
	%orig;
	// This disables swiping down so EasySwitcherX by sparkdev_ will not run if music is playing
	if (easyFix && playing && MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentOffset.y < 0) {
		MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize = CGSizeMake(MSHookIvar <UIScrollView*> (self,"_verticalScrollView").contentSize.width,0);
	}
}
%end
