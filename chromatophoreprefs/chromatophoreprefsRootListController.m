#include "chromatophoreprefsRootListController.h"

@implementation chromatophoreprefsRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)refreshEmoji{
	NSURLSessionDataTask *getEmojiDataTask = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/Samgisaninja/chromatophore/master/emoji.plist"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
		if (error) {
			UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
			[errorAlert addAction:dismissAction];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self presentViewController:errorAlert animated:TRUE completion:nil];
			});
		} else {
			if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.chromatophore.emoji.plist"]) {
				[[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.samgisaninja.chromatophore.emoji.plist" error:nil];
			}
			NSError *err;
			[data writeToFile:@"/var/mobile/Library/Preferences/com.samgisaninja.chromatophore.emoji.plist" options:NSDataWritingAtomic error:&err];
			if (err) {
				UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[err localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
				[errorAlert addAction:dismissAction];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self presentViewController:errorAlert animated:TRUE completion:nil];
				});
			} else {
				UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"Success" message:@"Emoji categories updates successfully." preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
				[successAlert addAction:dismissAction];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self presentViewController:successAlert animated:TRUE completion:nil];
				});
			}
		}
	}];
	[getEmojiDataTask resume];
}

@end
