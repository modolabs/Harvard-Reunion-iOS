#import "KGOWebViewController.h"
#import "KGORequestManager.h"
#import "KGOAppDelegate.h"
#import "KGOHTMLTemplate.h"
#import <QuartzCore/QuartzCore.h>

// UIWebView throws WebKit errors, but the WebKit framework can't be imported
// in iOS so we'll just reproduce the error constants here
enum {
    WebKitErrorCannotShowMIMEType = 100,
    WebKitErrorCannotShowURL = 101,
    WebKitErrorFrameLoadInterruptedByPolicyChange = 102
};

@implementation KGOWebViewController

@synthesize loadsLinksInternally, webView = _webView, delegate;
@synthesize HTMLString;

- (void)dealloc
{
    self.webView.delegate = nil;
    self.webView = nil;
    
    self.requestURL = nil;
    [_templateStack release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.delegate = self;

    [self.view addSubview:_webView];
    
    if (self.requestURL) {
        [_webView loadRequest:[NSURLRequest requestWithURL:self.requestURL]];
    }
    
    if (self.HTMLString != nil) {
        [_webView loadHTMLString:self.HTMLString baseURL:nil];
    }
}

- (void)fadeInDismissControls
{
    [self showDismissControlsAnimated:YES];
}

- (void)showDismissControlsAnimated:(BOOL)animated
{
    if (!_dismissView) {
        _dismissView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44)];
        _dismissView.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.8];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.titleLabel.textColor = [UIColor whiteColor];
        button.backgroundColor = [UIColor clearColor];
        button.layer.borderColor = [[UIColor colorWithWhite:0.8 alpha:1] CGColor];
        button.layer.borderWidth = 1;
        button.frame = CGRectMake(floor(self.view.frame.size.width / 4), 5, floor(self.view.frame.size.width / 2), 34);
        [button setTitle:NSLocalizedString(@"Exit this screen", nil) forState:UIControlStateNormal];
        [button addTarget:self.parentViewController
                   action:@selector(dismissModalViewControllerAnimated:)
         forControlEvents:UIControlEventTouchUpInside];
        [_dismissView addSubview:button];
        
        if (animated) {
            _dismissView.alpha = 0;
        }
        [self.view addSubview:_dismissView];
        
        if (animated) {
            [UIView animateWithDuration:1 animations:^(void) {
                _dismissView.alpha = 1;
            }];
        }
    }
}

- (NSURL *)requestURL
{
    return _requestURL;
}

- (void)setRequestURL:(NSURL *)requestURL
{
    [_requestURL release];
    _requestURL = [requestURL retain];
    
    if (_webView) {
        [_webView loadRequest:[NSURLRequest requestWithURL:self.requestURL]];
    }
}

- (void)retryRequest {
    [_webView loadRequest:[NSURLRequest requestWithURL:self.requestURL]];
}

- (void)applyTemplate:(NSString *)filename
{
    if (!_templateStack) {
        _templateStack = [[NSMutableArray alloc] init];
    }

    if ([_templateStack containsObject:filename]) {
        return;
    } else {
        [_templateStack addObject:filename];
    }
    
    KGOHTMLTemplate *template = [KGOHTMLTemplate templateWithPathName:filename];
    NSString *wrappedString = [template stringWithReplacements:[NSDictionary dictionaryWithObjectsAndKeys:HTMLString, @"BODY", nil]];
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle] resourcePath]];
    if (_webView) {
        [_webView loadHTMLString:wrappedString baseURL:url];
    } else {
        HTMLString = [wrappedString retain];
    }
}

- (void) showHTMLString: (NSString *) HTMLStringText
{
    [HTMLString release];
    self.HTMLString = HTMLStringText;
    
    if (_webView){
        [_webView loadHTMLString:self.HTMLString baseURL:nil];
    }
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma marke - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    DLog(@"loading request %@", [request URL]);
    
    NSURL *url = [request URL];
    NSString *scheme = [url scheme];
    
    // TODO: give delegates more control over other navigation types.
    // the other clauses in this method should just be the fallback for 
    // non-implementing delegates
    if (navigationType == UIWebViewNavigationTypeLinkClicked
        && [self.delegate respondsToSelector:@selector(webViewController:shouldOpenSystemBrowserForURL:)]
    ) {
        BOOL shouldOpenBrowser = [self.delegate webViewController:self shouldOpenSystemBrowserForURL:url];
        if (shouldOpenBrowser) {
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
        return !shouldOpenBrowser;
    }
    
    if ([scheme isEqualToString:[KGO_SHARED_APP_DELEGATE() defaultURLScheme]]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked
        && !self.loadsLinksInternally
        && ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])
    ) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (!_loadingView) {
        _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_loadingView startAnimating];
        _loadingView.center = self.view.center;
        [self.view addSubview:_loadingView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_loadingView removeFromSuperview];
    [_loadingView release];
    _loadingView = nil;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"%@", [error description]);
    
    // we seem to get to this point when our original request gets redirected
    // to a URL to which we return NO in -shouldStartLoadWithRequest.
    // TODO: figure out why we aren't being dismissed by other triggers
    if ([error code] == WebKitErrorFrameLoadInterruptedByPolicyChange) {
        if ([self.delegate respondsToSelector:@selector(webViewControllerFrameLoadInterrupted:)]) {
            [self.delegate webViewControllerFrameLoadInterrupted:self];
        }
    }
}

@end
