#import <UIKit/UIKit.h>


@interface WebInspectorServerHTTP : NSObject
{
    struct __CFSocket *_socket;
    unsigned short _port;
    int _serverFileDescriptor;
}

- (id)init;
- (void)start;
- (void)stop;
- (BOOL)isEnabled;
- (void)pushListing;
- (void)connectionReceived:(int)arg1;

@end



@interface WIPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) WebInspectorServerHTTP* inspectorServer;

@end
