#import "WIPAppDelegate.h"

@implementation WIPAppDelegate

@synthesize window = _window;
@synthesize inspectorServer;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [NSClassFromString(@"WebView") performSelector:@selector(_enableRemoteInspector)];
    self.inspectorServer = [[NSClassFromString(@"WebInspectorServerHTTP") alloc] init];
    [self.inspectorServer performSelector:NSSelectorFromString(@"start")];

    return YES;
}

@end
