@interface UIView ()
-(UIViewController *)_viewControllerForAncestor;
@end

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
UIView *chromatophoreBackgroundView;
UITableView *chromatophoreTableView;
UIKBKeyplaneView *currentKBKeyplaneView;
UIButton *returnToKeyboardButton;


static void apoptosis(){
	shouldHideOrigEmojiView = FALSE;
	[currentKBKeyplaneView setHidden:FALSE];
	[chromatophoreBackgroundView removeFromSuperview];
	chromatophoreBackgroundView = nil;
	[returnToKeyboardButton removeFromSuperview];
	returnToKeyboardButton = nil;
	[chromatophoreTableView removeFromSuperview];
	chromatophoreTableView = nil;
}
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

%hook UIViewController

-(void)viewDidAppear:(BOOL)arg1{
	if (![[[UITextInputMode currentInputMode] primaryLanguage] isEqualToString:@"emoji"]){
		apoptosis();
	}
}

-(void)viewDidDisappear:(BOOL)arg1{
	if (![[[UITextInputMode currentInputMode] primaryLanguage] isEqualToString:@"emoji"]){
		apoptosis();
	}
	%orig;
}

%end

%hook UIKBKeyplaneView

-(void)setEmojiKeyManager:(id/*UIKeyboardEmojiKeyDisplayController**/)arg1{
	%orig;
	currentKBKeyplaneView = self;
	for (int i = 0; i < (int)[UIKeyboardEmojiCategory numberOfCategories]; i++) {
		UIKeyboardEmojiCategory *category = [UIKeyboardEmojiCategory categoryForType:i];
		NSString *categoryName = [UIKeyboardEmojiCategory displayName:i];
		if (!categoryName || [categoryName containsString:@"Recent"] || [categoryName containsString:@"Frequently"] || ![category valueForKey:@"emoji"]) {
			continue;
		}
		NSMutableArray *emojiInCategory = [[NSMutableArray alloc] init];
		for (UIKeyboardEmoji *emote in [category valueForKey:@"emoji"]) {
			[emojiInCategory addObject:[emote emojiString]];
		}
		NSDictionary *categoryDict = @{
			 categoryName : emojiInCategory
		};
		[allEmojisAndCategories setObject:categoryDict forKey:[NSString stringWithFormat:@"%d", (int)[[allEmojisAndCategories allKeys] count]]];
	}
	float heightOfChromatophoreView = 0;
	for (UIViewController *vc in [[currentKeyboardWindow rootViewController] childViewControllers]) {
		if ([vc class] == %c(UICompatibilityInputViewController)) {
			heightOfChromatophoreView = vc.view.frame.size.height;
			break;
		}
	}
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	chromatophoreBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, (screenRect.size.height - heightOfChromatophoreView), screenRect.size.width, heightOfChromatophoreView)];
	[chromatophoreBackgroundView setBackgroundColor:[UIColor clearColor]];
	[chromatophoreBackgroundView setUserInteractionEnabled:FALSE];
	returnToKeyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[returnToKeyboardButton addTarget:self action:@selector(apoptosis) forControlEvents:UIControlEventTouchUpInside];
	[returnToKeyboardButton setTitle:@"Return to Keyboard" forState:UIControlStateNormal];
	[[returnToKeyboardButton titleLabel] setFont:[UIFont systemFontOfSize:15]];
	[returnToKeyboardButton sizeToFit];
	[returnToKeyboardButton setFrame:CGRectMake((screenRect.size.width - returnToKeyboardButton.frame.size.width - 10), (screenRect.size.height - heightOfChromatophoreView + 25 - (returnToKeyboardButton.frame.size.height/2)), returnToKeyboardButton.frame.size.width, returnToKeyboardButton.frame.size.height)];
	chromatophoreTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, (screenRect.size.height - heightOfChromatophoreView + 50), currentKeyboardWindow.rootViewController.view.frame.size.width, heightOfChromatophoreView - 50)];
	[chromatophoreTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"chromatophoreReuseIdentifier"];
	[chromatophoreTableView setDelegate:self];
	[chromatophoreTableView setDataSource:self];
	[chromatophoreTableView setBackgroundColor:[UIColor clearColor]];
	[[[currentKeyboardWindow rootViewController] view] addSubview:chromatophoreBackgroundView];
	[[[currentKeyboardWindow rootViewController] view] addSubview:chromatophoreTableView];
	[[[currentKeyboardWindow rootViewController] view] addSubview:returnToKeyboardButton];
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
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	return 	[[[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)section]] allKeys] objectAtIndex:0];
}

%new
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return [[allEmojisAndCategories allKeys] count];
}

%new
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return [[[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)section]] objectForKey:[[[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)section]] allKeys] objectAtIndex:0]] count];
}

%new
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chromatophoreReuseIdentifier" forIndexPath:indexPath];
	[[cell textLabel] setText:[[[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)[indexPath section]]] objectForKey:[[[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)[indexPath section]]] allKeys] objectAtIndex:0]] objectAtIndex:[indexPath row]]];
	[[cell contentView] setBackgroundColor:[UIColor clearColor]];
	[[cell backgroundView] setBackgroundColor:[UIColor clearColor]];
	[cell setBackgroundColor:[UIColor clearColor]];
    return cell;
}

%new
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
}

%new
-(void)apoptosis{
	apoptosis();
}

%end

%hook UIRemoteKeyboardWindow

-(void)detachBindable{
	currentKeyboardWindow = self;
    %orig;
}

%end

%ctor{
	allEmojisAndCategories = [[NSMutableDictionary alloc] init];
}

