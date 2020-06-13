@interface UIView ()
-(UIViewController *)_viewControllerForAncestor;
@end


@interface UIRemoteKeyboardWindow : UIWindow
@end

UIRemoteKeyboardWindow *currentKeyboardWindow;
BOOL shouldHideOrigEmojiView;
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

@interface UIKBKeyplaneView : UIView <UITableViewDataSource, UITableViewDelegate>
@end

%hook UIKBKeyplaneView

-(void)setEmojiKeyManager:(id/*UIKeyboardEmojiKeyDisplayController*/)arg1{
	%orig;
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

%hook UIRemoteKeyboardWindow

-(void)detachBindable{
	currentKeyboardWindow = self;
    %orig;
}

%end

