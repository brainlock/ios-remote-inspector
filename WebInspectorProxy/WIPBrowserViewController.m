#import "WIPBrowserViewController.h"
#import "WIPTCPProxy.h"

@interface WIPBrowserViewController ()
<UIWebViewDelegate>
{
    UIWebView* wview;
    WIPTCPProxy* proxy;
}

@property (readonly) UIWebView* wview;
@property (strong) NSURL* websiteURL;
@property (readonly) WIPTCPProxy* proxy;

@end

@implementation WIPBrowserViewController

@synthesize websiteURL;


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:YES];

    CGRect frame = self.view.frame;
    frame.origin.y = 0;
    self.view.frame = frame;
    self.wview.frame = frame;
    [self.view addSubview:self.wview];

    self.wview.scrollView.scrollEnabled = NO;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.proxy stop];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (UIWebView*) wview {
    if (!wview) {
        wview = [UIWebView new];
        wview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        wview.delegate = self;
    }
    return wview;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    DebugLog(@"Webview loaded.");
}

- (void)loadWebsite:(NSURL*)url {
    NSString* scheme = url.scheme ? url.scheme : @"http";
    NSString* query = url.query ? [@"?" stringByAppendingString:url.query] : @"";
    NSString* fragment = url.fragment ? [@"#" stringByAppendingString:url.fragment] : @"";

    self.websiteURL = [[NSURL alloc] initWithString:
            [NSString stringWithFormat:@"%@://%@/%@%@",
                                       scheme, url.path, query, fragment
            ]];

    DebugLog(@"loading url %@", self.websiteURL);
    [self.wview stopLoading];
    [self.wview loadRequest:
            [NSURLRequest requestWithURL:self.websiteURL]];
    [self.proxy stop];
    [self.proxy start];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (!self.navigationController.isNavigationBarHidden) {
                [self.navigationController setNavigationBarHidden:YES animated:YES];
            }
        });
    }
}

- (IBAction)refreshTapped:(id)sender {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.wview reload];
}

- (WIPTCPProxy*) proxy {
    if (!proxy) {
        proxy = [WIPTCPProxy new];
    }
    return proxy;
}


@end
