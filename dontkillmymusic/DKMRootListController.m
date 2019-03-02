// This is the implementation file for the settings Preferences
#include "DKMRootListController.h"

// Must include for respring button
#include <spawn.h>
#include <signal.h>

@implementation DKMRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}
- (void) reset {
UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset All Settings to Defualt"
message:@"Are You Sure You Want To Reset All Settings to Defualt?"
preferredStyle:UIAlertControllerStyleActionSheet];

UIAlertAction *resetBtn = [UIAlertAction actionWithTitle:@"Reset All Settings to Defualt"
style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
	for(PSSpecifier *specifier in [self specifiers]) {
							[super setPreferenceValue:[specifier propertyForKey:@"default"] specifier:specifier];
		}
	[self reloadSpecifiers];
}];

UIAlertAction *cancelBtn = [UIAlertAction actionWithTitle:@"Cancel"
style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
	//nothing lol
}];

[alert addAction:resetBtn];
[alert addAction:cancelBtn];

[self presentViewController:alert animated:YES completion:nil];
}
		//Github source code button
	- (void) git {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://github.com/Karimo299/DontKillMyMusic"]];
	}
		//Twitter button
	- (void) tweet {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://twitter.com/karimo299"]];
	}

	- (void) tweetHaste {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://twitter.com/hasteDesigns"]];
	}

		//Reddit button
	- (void)reddit {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://reddit.com/user/Karimo299"]];
	}

	//Respring button
- (IBAction)respring {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Respring"
	message:@"Are You Sure You Want To Respring?"
	preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction *respringBtn = [UIAlertAction actionWithTitle:@"Respring"
	style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
		pid_t pid;
		int status;
		const char* args[] = {"killall", "SpringBoard", NULL};
		posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char*
		const*)args, NULL);
		waitpid(pid, &status, WEXITED);
	}];

	UIAlertAction *cancelBtn = [UIAlertAction actionWithTitle:@"Cancel"
	style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
		//nothing lol
	}];
[alert addAction:respringBtn];
[alert addAction:cancelBtn];

[self presentViewController:alert animated:YES completion:nil];
}
@end
