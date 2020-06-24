@interface UIView ()
-(UIViewController *)_viewControllerForAncestor;
@end

@interface UIRemoteKeyboardWindow : UIWindow
@end

@interface UIKBKeyplaneView : UIView <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate>
@property (strong, nonatomic) UISearchController *searchController;
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

@interface UIWindow ()
+(UIWindow *)keyWindow;
@end

NSMutableDictionary *allEmojisAndCategories;
UIView *chromatophoreBackgroundView;
UITableView *chromatophoreTableView;
UIKBKeyplaneView *currentKBKeyplaneView;
UIButton *returnToKeyboardButton;
UIView *textBubbleView;
BOOL shouldRaiseTextBubbleView;
CGRect origTextBubbleFrame;
UILabel *emojiPrettyLabel;
UIButton *searchButton;
float heightOfChromatophoreView;
float yDiff;
NSMutableArray *allEmojis;
NSMutableArray *allEmojisForFilter;
NSMutableArray *filteredEmojis;
BOOL isFiltered;
id currentTextEditor;
UITextRange *cursorPos;
id userInfo;

static void apoptosis(){
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

@interface chromatophoreTableView


%group Default

%hook UIViewController

-(void)viewDidLoad{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
	%orig;
}

-(void)viewDidDisappear:(BOOL)arg1{
	if ([self class] != NSClassFromString(@"UICompatibilityInputViewController")){
		if ([self class] != NSClassFromString(@"UISystemInputAssistantViewController")){
			if ([self class] != NSClassFromString(@"UIPredictionViewController")){
				apoptosis();
			}
		}
	}
	%orig;
}

-(void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	%orig;
}

%new
-(void)keyboardWillChangeFrame:(NSNotification *)arg1{
	CGRect keyboardRect = [arg1.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	heightOfChromatophoreView = keyboardRect.size.height;
}

%end

%hook UITextView

-(void)textInputDidChangeSelection:(UITextView *)arg1{
	currentTextEditor = self;
	cursorPos = [self selectedTextRange];
	%orig;
}

%end

%hook UITextField

-(void)fieldEditorDidChangeSelection:(id)arg1{
	currentTextEditor = self;
	cursorPos = [self selectedTextRange];
	%orig;
}

%end

%hook UIKBKeyplaneView
%property (strong, nonatomic) UISearchController *searchController;

-(void)setEmojiKeyManager:(id/*UIKeyboardEmojiKeyDisplayController**/)arg1{
	%orig;
	
	allEmojis = [[NSMutableArray alloc] init];
	for (int a = 0; a < (int)[UIKeyboardEmojiCategory numberOfCategories]; a++) {
		UIKeyboardEmojiCategory *category = [UIKeyboardEmojiCategory categoryForType:a];
		for (UIKeyboardEmoji *emote in [category valueForKey:@"emoji"]) {
			if (![allEmojis containsObject:[emote emojiString]]) {
				[allEmojis addObject:[emote emojiString]];
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
	NSMutableArray *unknownEmoji = [[NSMutableArray alloc] initWithArray:allEmojis];
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
		[unknownDict setObject:emojiDict forKey:[NSString stringWithFormat:@"%d", ((int)[[unknownDict allKeys] count] - 1)]];

	}
	[allEmojisAndCategories setObject:unknownDict forKey:[NSString stringWithFormat:@"%d", (int)[[allEmojisAndCategories allKeys] count]]];
	allEmojisForFilter = [[NSMutableArray alloc] init];
	for (int d = 0; d < [allEmojisAndCategories count]; d++) {
        NSDictionary *categoryDictionary = [allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", d]];
        for (int e = 0; e < ([[categoryDictionary allKeys] count] - 1); e++) {
            NSDictionary *emojiDict = [categoryDictionary objectForKey:[NSString stringWithFormat:@"%d", e]];
            [allEmojisForFilter addObject:emojiDict];
        }
    }
	
	
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	chromatophoreBackgroundView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent]];
	[chromatophoreBackgroundView setFrame:CGRectMake(0, (screenRect.size.height - heightOfChromatophoreView), screenRect.size.width, heightOfChromatophoreView)];
	[chromatophoreBackgroundView setUserInteractionEnabled:FALSE];
	returnToKeyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[returnToKeyboardButton addTarget:self action:@selector(apoptosis) 	forControlEvents:UIControlEventTouchUpInside];
	[returnToKeyboardButton setTitle:@"Return to Keyboard" forState:UIControlStateNormal];
	[[returnToKeyboardButton titleLabel] setFont:[UIFont systemFontOfSize:15]];
	[returnToKeyboardButton sizeToFit];
	[returnToKeyboardButton setFrame:CGRectMake((screenRect.size.width - returnToKeyboardButton.frame.size.width - 10), (screenRect.size.height - heightOfChromatophoreView + 25 - (returnToKeyboardButton.frame.size.height/2)), returnToKeyboardButton.frame.size.width, returnToKeyboardButton.frame.size.height)];
	chromatophoreTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, (screenRect.size.height - heightOfChromatophoreView + 50), screenRect.size.width, heightOfChromatophoreView - 50)];
	[chromatophoreTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"chromatophoreReuseIdentifier"];
	[chromatophoreTableView setDelegate:self];
	[chromatophoreTableView setDataSource:self];
	[chromatophoreTableView setBackgroundColor:[UIColor clearColor]];
	emojiPrettyLabel = [[UILabel alloc] init];
	[emojiPrettyLabel setText:@"Emoji"];
	[emojiPrettyLabel setFont:[UIFont boldSystemFontOfSize:19]];
	[emojiPrettyLabel sizeToFit];
	[emojiPrettyLabel setFrame:CGRectMake(10, (screenRect.size.height - heightOfChromatophoreView + 25 - (emojiPrettyLabel.frame.size.height/2)), emojiPrettyLabel.frame.size.width, emojiPrettyLabel.frame.size.height)];
	searchButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[searchButton addTarget:self action:@selector(makeBig) forControlEvents:UIControlEventTouchUpInside];
	[searchButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/chromatophoreprefs.bundle/search.png"] forState:UIControlStateNormal];
	[searchButton setFrame:CGRectMake((15 + emojiPrettyLabel.frame.size.width), (screenRect.size.height - heightOfChromatophoreView + 15), 20, 20)];
	if ([[[UIDevice currentDevice] systemVersion] floatValue] > 12.99){
		[searchButton setTintColor:[UIColor systemGrayColor]];
	} else {
		[searchButton setTintColor:[UIColor grayColor]];
	}
	[[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
	[[[[UIWindow keyWindow] rootViewController] view] addSubview:chromatophoreBackgroundView];
	[[[[UIWindow keyWindow] rootViewController] view] addSubview:chromatophoreTableView];
	[[[[UIWindow keyWindow] rootViewController] view] addSubview:returnToKeyboardButton];
	[[[[UIWindow keyWindow] rootViewController] view] addSubview:emojiPrettyLabel];
	[[[[UIWindow keyWindow] rootViewController] view] addSubview:searchButton];
}

%new
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	if (isFiltered) {
		return @"Search";
	} else {
		return [[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)section]] objectForKey:@"name"];
	}
}

%new
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	if (isFiltered) {
		return 1;
	} else {
		return [[allEmojisAndCategories allKeys] count];
	}
}

%new
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	if (isFiltered) {
		return [filteredEmojis count];
	} else {
		return ([[[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)section]] allKeys] count] - 1);
	}
}

%new
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"chromatophoreReuseIdentifier"];
	if (isFiltered) {
		[[cell textLabel] setText:[[filteredEmojis objectAtIndex:[indexPath row]] objectForKey:@"string"]];
		[[cell detailTextLabel] setText:[[filteredEmojis objectAtIndex:[indexPath row]] objectForKey:@"name"]];
	} else {
		[[cell textLabel] setText:[[[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)[indexPath section]]] objectForKey:[NSString stringWithFormat:@"%d", (int)[indexPath row]]] objectForKey:@"string"]];
		[[cell detailTextLabel] setText:[[[allEmojisAndCategories objectForKey:[NSString stringWithFormat:@"%d", (int)[indexPath section]]] objectForKey:[NSString stringWithFormat:@"%d", (int)[indexPath row]]] objectForKey:@"name"]];
	}
	[[cell contentView] setBackgroundColor:[UIColor clearColor]];
	[[cell backgroundView] setBackgroundColor:[UIColor clearColor]];
	[cell setBackgroundColor:[UIColor clearColor]];
    return cell;
}

%new
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[currentTextEditor replaceRange:cursorPos withText:[[[self tableView:chromatophoreTableView cellForRowAtIndexPath:indexPath] textLabel] text]];
	[tableView deselectRowAtIndexPath:indexPath animated:TRUE];
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
	[searchButton removeFromSuperview];
	searchButton = nil;
	[self setSearchController:[[UISearchController alloc] initWithSearchResultsController:nil]];
    [[self searchController] setSearchResultsUpdater:self];
    [[self searchController] setObscuresBackgroundDuringPresentation:FALSE];
    [[[self searchController] searchBar] setDelegate:self];
    [chromatophoreTableView setTableHeaderView:[[self searchController] searchBar]];
    [[[self searchController] searchBar] sizeToFit];
}

%new
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if ([[[searchController searchBar] text] length] > 0) {
        filteredEmojis = [[NSMutableArray alloc] init];
        for (NSDictionary *emojiDict in allEmojisForFilter) {
            NSString *emojiName = [emojiDict objectForKey:@"name"];
            NSRange range = [emojiName rangeOfString:[[searchController searchBar] text] options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) {
                [filteredEmojis addObject:emojiDict];
            }
        }
		isFiltered = TRUE;
        [chromatophoreTableView reloadData];
    } else {
        isFiltered = FALSE;
        [chromatophoreTableView reloadData];
    }
}

%end

%end

%group Messages

%hook CKMessageEntryContentView

-(void)layoutSubviews{
    textBubbleView = [[self superview] superview];
    %orig;
}

%end


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

