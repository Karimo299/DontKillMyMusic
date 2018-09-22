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
		//Github source code button
	- (void) git {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://github.com/karimo299"]];
	}
		//Twitter button
	- (void) tweet {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://twitter.com/karimo299"]];
	}
		//Reddit button
	- (void)reddit {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://reddit.com/user/Karimo299"]];
	}

	//Respring button
	- (void) respring {
		pid_t pid;
		int status;
		const char *argv[] = {"killall", "SpringBoard", NULL};
		posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)argv, NULL);
		waitpid(pid, &status, WEXITED);
	}
@end
