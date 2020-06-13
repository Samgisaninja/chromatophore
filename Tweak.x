@interface UIRemoteKeyboardWindow : UIWindow
@end

@interface UIKBKeyplaneView : UIView <UITableViewDataSource, UITableViewDelegate>
@end

@interface UIKeyboardEmojiCategory : NSObject
+(id)categories;
+(long long)numberOfCategories;
+(UIKeyboardEmojiCategory *)categoryForType:(int)arg1;
+(NSString *)displayName:(long long)arg1;
-(NSArray *)emoji;
@end

@interface UIKeyboardEmoji: NSObject
-(NSString *)emojiString;
@end


UIRemoteKeyboardWindow *currentKeyboardWindow;
BOOL shouldHideOrigEmojiView;
NSMutableDictionary *allEmojisAndCategories;
/*
@interface chromatophoreTableViewController : UITableViewController
@end

@implementation chromatophoreTableViewController

-(void)viewDidLoad{
	
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chromatophoreReuseIdentifier" forIndexPath:indexPath];
	[[cell textLabel] setText:[NSString stringWithFormat:@"%d", (int)[indexPath row]]];
	[[cell contentView] setBackgroundColor:[UIColor clearColor]];
	[[cell backgroundView] setBackgroundColor:[UIColor clearColor]];
	[cell setBackgroundColor:[UIColor clearColor]];
    return cell;
}

@end


*/

%hook UIKBKeyplaneView

-(void)setEmojiKeyManager:(id/*UIKeyboardEmojiKeyDisplayController*/)arg1{
	%orig;
	for (int i = 0; i < (int)[UIKeyboardEmojiCategory numberOfCategories]; i++) {
		UIKeyboardEmojiCategory *category = [UIKeyboardEmojiCategory categoryForType:i];
		NSString *categoryName = [UIKeyboardEmojiCategory displayName:i];
		if (!categoryName || [categoryName hasSuffix:@"Recent"] || ![category valueForKey:@"emoji"]) {
			continue;
		}
		NSMutableArray *emojiInCategory = [[NSMutableArray alloc] init];
		for (UIKeyboardEmoji *emote in [category valueForKey:@"emoji"]) {
			[emojiInCategory addObject:[emote emojiString]];
		}
		[allEmojisAndCategories setObject:emojiInCategory forKey:categoryName];
	}
	NSMutableArray *allEmoji = [[NSMutableArray alloc] init];
	for (NSString *key in [allEmojisAndCategories allKeys]) {
		[allEmoji addObject:[[allEmojisAndCategories objectForKey:key] componentsJoinedByString:@" "]];
	}
	[[UIPasteboard generalPasteboard] setString:[allEmoji componentsJoinedByString:@" "]];
	NSLog(@"CHROMATOPHORE: pasteboard updated!");
	
	float heightOfChromatophoreView = 0;
	for (UIViewController *vc in [[currentKeyboardWindow rootViewController] childViewControllers]) {
		if ([vc class] == %c(UICompatibilityInputViewController)) {
			heightOfChromatophoreView = vc.view.frame.size.height;
			break;
		}
	}
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	UITableView *chromatophoreTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, (screenRect.size.height - heightOfChromatophoreView), currentKeyboardWindow.rootViewController.view.frame.size.width, heightOfChromatophoreView)];
	[chromatophoreTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"chromatophoreReuseIdentifier"];
	[chromatophoreTableView setDelegate:self];
	[chromatophoreTableView setDataSource:self];
	[chromatophoreTableView setBackgroundColor:[UIColor clearColor]];
	[[[currentKeyboardWindow rootViewController] view] addSubview:chromatophoreTableView];
	shouldHideOrigEmojiView = TRUE;
	[self setHidden:TRUE];
}

-(void)setHidden:(BOOL)arg1{
	if (shouldHideOrigEmojiView) {
		%orig(TRUE);
	} else {
		%orig;
	}
}

%new
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 1;
}

%new
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return 100;
}

%new
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chromatophoreReuseIdentifier" forIndexPath:indexPath];
	[[cell textLabel] setText:[NSString stringWithFormat:@"%d", (int)[indexPath row]]];
	[[cell contentView] setBackgroundColor:[UIColor clearColor]];
	[[cell backgroundView] setBackgroundColor:[UIColor clearColor]];
	[cell setBackgroundColor:[UIColor clearColor]];
    return cell;
}

%new
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	NSLog(@"CHROMATOPHRE! %d", (int)[indexPath row]);
}

%end
/*
%hook UIKeyboardEmojiCategory

-(void)setEmoji:(NSArray*)arg1 {
	NSLog(@"CHROMATOPHORE: %@ and %@", [self name], [self emoji]);
	//[allEmojisAndCategories setObject: forKey:[self name]]
    %orig;
}


%end
*/

%hook UIRemoteKeyboardWindow

-(void)detachBindable{
	currentKeyboardWindow = self;
    %orig;
}

%end

%ctor{
	allEmojisAndCategories = [[NSMutableDictionary alloc] init];
}

