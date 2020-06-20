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

@interface CKMessageEntryContentView : UIView
@end

@interface UIKeyboardImpl : UIView
+(UIKeyboardImpl *)sharedInstance;
-(void)insertText:(NSString *)arg1;
@end

@interface UISystemKeyboardDockController : UIViewController
@end

@interface UIColor ()
+(UIColor *)systemGrayColor;
@end

UIRemoteKeyboardWindow *currentKeyboardWindow;
BOOL shouldHideOrigEmojiView;
NSMutableDictionary *allEmojisAndCategories;
UIView *chromatophoreBackgroundView;
UITableView *chromatophoreTableView;
UIKBKeyplaneView *currentKBKeyplaneView;
UIButton *returnToKeyboardButton;
UIView *textBubbleView;
BOOL shouldRaiseTextBubbleView;
CGRect origTextBubbleFrame;
float heightOfDockController;
UILabel *emojiPrettyLabel;
UIButton *searchButton;
float heightOfChromatophoreView;
float yDiff;

static void apoptosis(){
	shouldHideOrigEmojiView = FALSE;
	[currentKBKeyplaneView setHidden:FALSE];
	shouldRaiseTextBubbleView = FALSE;
	[textBubbleView setFrame:origTextBubbleFrame];
	[chromatophoreBackgroundView removeFromSuperview];
	chromatophoreBackgroundView = nil;
	[searchButton removeFromSuperview];
	searchButton = nil;
	[emojiPrettyLabel removeFromSuperview];
	emojiPrettyLabel = nil;
	[returnToKeyboardButton removeFromSuperview];
	returnToKeyboardButton = nil;
	[chromatophoreTableView removeFromSuperview];
	chromatophoreTableView = nil;
}

%group Default

%hook UIViewController

-(void)viewDidAppear:(BOOL)arg1{
	if (![[[UITextInputMode currentInputMode] primaryLanguage] isEqualToString:@"emoji"]){
		apoptosis();
	}
	%orig;
}

-(void)viewDidDisappear:(BOOL)arg1{
	if (![[[UITextInputMode currentInputMode] primaryLanguage] isEqualToString:@"emoji"]){
		apoptosis();
	}
	%orig;
}

%end

%hook UIKeyboardEmojiKeyDisplayController

+(void)writeEmojiDefaultsAndReleaseActiveInputView{
	%orig;
	apoptosis();
}

%end

%hook UIKBKeyplaneView

-(void)setEmojiKeyManager:(id/*UIKeyboardEmojiKeyDisplayController**/)arg1{
	%orig;
	
	NSMutableArray *allEmoji = [[NSMutableArray alloc] init];
	for (int a = 0; a < (int)[UIKeyboardEmojiCategory numberOfCategories]; a++) {
		UIKeyboardEmojiCategory *category = [UIKeyboardEmojiCategory categoryForType:a];
		//NSString *categoryName = [UIKeyboardEmojiCategory displayName:a];
		for (UIKeyboardEmoji *emote in [category valueForKey:@"emoji"]) {
			if (![allEmoji containsObject:[emote emojiString]]) {
				[allEmoji addObject:[emote emojiString]];
			}
		}
	}
	NSMutableArray *knownEmoji = [[NSMutableArray alloc] init];
	allEmojisAndCategories = [[NSMutableDictionary alloc] initWithContentsOfURL:[NSURL fileURLWithPath:@"/var/mobile/Library/Preferences/com.samgisaninja.chromatophore.emoji.plist"]];
	for (int b = 0; b < [[allEmojisAndCategories allKeys] count]; b++) {
		NSDictionary *customCategory = [allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", b]];
		for (int c = 0; c < ([customCategory count] - 1); c++){
			NSDictionary *emojiInfoDict = [customCategory objectForKey:[NSString stringWithFormat:@"%d", c]];
			[knownEmoji addObject:[emojiInfoDict objectForKey:@"string"]];
		}
	}
	NSMutableArray *unknownEmoji = [[NSMutableArray alloc] initWithArray:allEmoji];
	[unknownEmoji removeObjectsInArray:knownEmoji];
	NSMutableDictionary *unknownDict = [[NSMutableDictionary alloc] init];
	[unknownDict setObject:@"Ungrouped" forKey:@"name"];
	for (NSString *unknownEmojiStr in unknownEmoji){
		NSMutableString *emojiMutStr = [[NSMutableString alloc] initWithString:unknownEmojiStr];
		CFMutableStringRef emojiCFStr = (__bridge CFMutableStringRef)emojiMutStr;
		CFRange range = CFRangeMake(0, CFStringGetLength(emojiCFStr));
		CFStringTransform(emojiCFStr, &range, kCFStringTransformToUnicodeName, FALSE);
		NSMutableString *emojiNameMutable = (__bridge NSMutableString *)emojiCFStr;
		NSString *emojiName = [[[emojiNameMutable stringByReplacingOccurrencesOfString:@"\\N" withString:@""] stringByReplacingOccurrencesOfString:@"{" withString:@" "] stringByReplacingOccurrencesOfString:@"}" withString:@" "];
		NSDictionary *emojiDict = @{
			@"string" : unknownEmojiStr,
			@"name" : emojiName
		};
		[unknownDict setObject:emojiDict forKey:[NSString stringWithFormat:@"%d", (int)[[unknownDict allKeys] count]]];
	}
	[allEmojisAndCategories setObject:unknownDict forKey:[NSString stringWithFormat:@"%d", (int)[[allEmojisAndCategories allKeys] count]]];
	
	currentKBKeyplaneView = self;
	for (UIViewController *vc in [[currentKeyboardWindow rootViewController] childViewControllers]) {
		if ([vc class] == %c(UICompatibilityInputViewController)) {
			heightOfChromatophoreView = vc.view.frame.size.height;
			break;
		}
	}
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	chromatophoreBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, (screenRect.size.height - heightOfChromatophoreView - heightOfDockController), screenRect.size.width, heightOfChromatophoreView)];
	[chromatophoreBackgroundView setBackgroundColor:[UIColor clearColor]];
	[chromatophoreBackgroundView setUserInteractionEnabled:FALSE];
	returnToKeyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[returnToKeyboardButton addTarget:self action:@selector(apoptosis) 	forControlEvents:UIControlEventTouchUpInside];
	[returnToKeyboardButton setTitle:@"Return to Keyboard" forState:UIControlStateNormal];
	[[returnToKeyboardButton titleLabel] setFont:[UIFont systemFontOfSize:15]];
	[returnToKeyboardButton sizeToFit];
	[returnToKeyboardButton setFrame:CGRectMake((screenRect.size.width - returnToKeyboardButton.frame.size.width - 10), (screenRect.size.height - heightOfChromatophoreView - heightOfDockController + 25 - (returnToKeyboardButton.frame.size.height/2)), returnToKeyboardButton.frame.size.width, returnToKeyboardButton.frame.size.height)];
	chromatophoreTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, (screenRect.size.height - heightOfDockController - heightOfChromatophoreView + 50), currentKeyboardWindow.rootViewController.view.frame.size.width, heightOfChromatophoreView - 50)];
	[chromatophoreTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"chromatophoreReuseIdentifier"];
	[chromatophoreTableView setDelegate:self];
	[chromatophoreTableView setDataSource:self];
	[chromatophoreTableView setBackgroundColor:[UIColor clearColor]];
	emojiPrettyLabel = [[UILabel alloc] init];
	[emojiPrettyLabel setText:@"Emoji"];
	[emojiPrettyLabel setFont:[UIFont boldSystemFontOfSize:19]];
	[emojiPrettyLabel sizeToFit];
	[emojiPrettyLabel setFrame:CGRectMake(10, (screenRect.size.height - heightOfChromatophoreView - heightOfDockController + 25 - (emojiPrettyLabel.frame.size.height/2)), emojiPrettyLabel.frame.size.width, emojiPrettyLabel.frame.size.height)];
	searchButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[searchButton addTarget:self action:@selector(makeBig) forControlEvents:UIControlEventTouchUpInside];
	[searchButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/chromatophoreprefs.bundle/search.png"] forState:UIControlStateNormal];
	[searchButton setFrame:CGRectMake((15 + emojiPrettyLabel.frame.size.width), (screenRect.size.height - heightOfChromatophoreView - heightOfDockController + 15), 20, 20)];
	if ([[[UIDevice currentDevice] systemVersion] floatValue] > 12.99){
		[searchButton setTintColor:[UIColor systemGrayColor]];
	} else {
		[searchButton setTintColor:[UIColor grayColor]];
	}
	[[[currentKeyboardWindow rootViewController] view] addSubview:chromatophoreBackgroundView];
	[[[currentKeyboardWindow rootViewController] view] addSubview:chromatophoreTableView];
	[[[currentKeyboardWindow rootViewController] view] addSubview:returnToKeyboardButton];
	[[[currentKeyboardWindow rootViewController] view] addSubview:emojiPrettyLabel];
	[[[currentKeyboardWindow rootViewController] view] addSubview:searchButton];
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
	return [[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)section]] objectForKey:@"name"];
}

%new
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return [[allEmojisAndCategories allKeys] count];
}

%new
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return ([[[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)section]] allKeys] count] - 1);
}

%new
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"chromatophoreReuseIdentifier"];
	[[cell textLabel] setText:[[[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)[indexPath section]]] objectForKey:[NSString stringWithFormat:@"%d", (int)[indexPath row]]] objectForKey:@"string"]];
	[[cell detailTextLabel] setText:[[[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)[indexPath section]]] objectForKey:[NSString stringWithFormat:@"%d", (int)[indexPath row]]] objectForKey:@"name"]];
	[[cell contentView] setBackgroundColor:[UIColor clearColor]];
	[[cell backgroundView] setBackgroundColor:[UIColor clearColor]];
	[cell setBackgroundColor:[UIColor clearColor]];
    return cell;
}

%new
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[[UIKeyboardImpl sharedInstance] insertText:[[[self tableView:chromatophoreTableView cellForRowAtIndexPath:indexPath] textLabel] text]];
}

%new
-(void)apoptosis{
	apoptosis();
}

%new
-(void)makeBig{
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	yDiff = searchButton.frame.origin.y - (225 - searchButton.frame.size.height/2);
	[chromatophoreBackgroundView setFrame:CGRectMake(0, 200, screenRect.size.width, (screenRect.size.height - 100))];
	[chromatophoreTableView setFrame:CGRectMake(0, 250, screenRect.size.width, (screenRect.size.height - 150))];
	[returnToKeyboardButton setFrame:CGRectMake(returnToKeyboardButton.frame.origin.x, (225 - returnToKeyboardButton.frame.size.height/2), returnToKeyboardButton.frame.size.width, returnToKeyboardButton.frame.size.height)];
	shouldRaiseTextBubbleView = TRUE;
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.MobileSMS"]){
		[textBubbleView setFrame:CGRectMake(0, 0, 0, 0)];
	}
	[emojiPrettyLabel setFrame:CGRectMake(emojiPrettyLabel.frame.origin.x, 225 - emojiPrettyLabel.frame.size.height/2, emojiPrettyLabel.frame.size.width, emojiPrettyLabel.frame.size.height)];
	[searchButton setFrame:CGRectMake(searchButton.frame.origin.x, 225 - searchButton.frame.size.height/2, searchButton.frame.size.width, searchButton.frame.size.height)];
}

%end

%hook UIRemoteKeyboardWindow

-(void)detachBindable{
	currentKeyboardWindow = self;
    %orig;
}

%end





%hook CKMessageEntryContentView

-(void)layoutSubviews{
    textBubbleView = [[self superview] superview];
    %orig;
}

%end

%hook UISystemKeyboardDockController

-(void)viewDidLoad{
	heightOfDockController = 65;
	%orig;
}

%end

%end

%group Messages

%hook UIView

-(void)setFrame:(CGRect)arg1{
	if (self == textBubbleView){
		if (shouldRaiseTextBubbleView) {
			%orig(CGRectMake(arg1.origin.x, - yDiff, origTextBubbleFrame.size.width, origTextBubbleFrame.size.height));
		} else {
			origTextBubbleFrame = arg1;
			%orig;
		}
	} else {
		%orig;
	}
}

%end

%end

%ctor{
	if ([[[[NSProcessInfo processInfo] arguments] objectAtIndex:0] containsString:@"/Application"] || [[[[NSProcessInfo processInfo] arguments] objectAtIndex:0] containsString:@"SpringBoard.app"]) {
		allEmojisAndCategories = [[NSMutableDictionary alloc] init];
		
		%init(Default);
		if ([[[[NSProcessInfo processInfo] arguments] objectAtIndex:0] containsString:@"MobileSMS.app"]){
			%init(Messages);
		}
	}
}

