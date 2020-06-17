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

static void apoptosis(){
	shouldHideOrigEmojiView = FALSE;
	shouldRaiseTextBubbleView = FALSE;
	[textBubbleView setFrame:origTextBubbleFrame];
	[currentKBKeyplaneView setHidden:FALSE];
	[chromatophoreBackgroundView removeFromSuperview];
	chromatophoreBackgroundView = nil;
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
	[[[currentKeyboardWindow rootViewController] view] addSubview:chromatophoreBackgroundView];
	[[[currentKeyboardWindow rootViewController] view] addSubview:chromatophoreTableView];
	[[[currentKeyboardWindow rootViewController] view] addSubview:returnToKeyboardButton];
	[[[currentKeyboardWindow rootViewController] view] addSubview:emojiPrettyLabel];
	shouldHideOrigEmojiView = TRUE;
	shouldRaiseTextBubbleView = TRUE;
	[textBubbleView setFrame:CGRectMake(0, 0, 0, 0)];
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
	[[UIKeyboardImpl sharedInstance] insertText:[[[self tableView:chromatophoreTableView cellForRowAtIndexPath:indexPath] textLabel] text]];
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
			%orig(CGRectMake(arg1.origin.x, -200, arg1.size.width, arg1.size.height));
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

