#import "WIPTCPProxy.h"
#import "GCDAsyncSocket.h"

#define EXTERNAL_PORT 55555
#define INSPECTOR_HOST @"::1"
#define INSPECTOR_PORT 9999

#define PROXYTIMEOUT -1

@interface WIPTCPProxy ()
<NSNetServiceDelegate>
{
    BOOL running;
}

@property (strong) NSMutableArray* waitingExternalSockets;
@property (strong) NSMutableDictionary* socketMap;
@property (strong) GCDAsyncSocket* externalSocket;
@property (strong) NSNetService* netService;

@end


@implementation WIPTCPProxy

@synthesize socketMap;
@synthesize externalSocket;
@synthesize waitingExternalSockets;
@synthesize netService;


- (id) init {
    self = [super init];
    if (self) {
        self.socketMap = [NSMutableDictionary new];
        self.waitingExternalSockets = [NSMutableArray new];

        self.externalSocket = [[GCDAsyncSocket alloc]
                               initWithDelegate:self
                                  delegateQueue:dispatch_get_current_queue()];

        self.netService = [[NSNetService alloc] initWithDomain:@"local."
                                                          type:@"_http._tcp."
                                                          name:@"Remote Webkit Inspector"
                                                          port:EXTERNAL_PORT];
        self.netService.delegate = self;

        running = NO;
    }
    return self;
}

- (void) start {
    if (running) return;
    running = YES;
    [self listenOnExternal];
    [self.netService publish];
    DebugLog(@"Started proxy.");
}

- (void) stop {
    if (!running) return;

    running = NO;
    [self.externalSocket disconnect];
    for (NSValue* srcKey in self.socketMap) {
        GCDAsyncSocket* outSock = [self.socketMap objectForKey:srcKey];
        if (outSock) {
            [outSock setDelegate:nil delegateQueue:NULL];
            [outSock disconnect];
        }
        GCDAsyncSocket* inSock = [self.socketMap objectForKey:[NSValue valueWithNonretainedObject:outSock]];
        if (inSock) {
            [inSock setDelegate:nil delegateQueue:NULL];
            [inSock disconnect];
        }
    }
    self.socketMap = [NSMutableDictionary new];
    self.waitingExternalSockets = [NSMutableArray new];

    [self.netService stop];
    DebugLog(@"Stopped proxy.");
}

- (void) listenOnExternal {
    NSError* err = nil;
    if ([self.externalSocket acceptOnPort:EXTERNAL_PORT error:&err]) {
        DebugLog(@"Proxy listening on port %d", EXTERNAL_PORT);
    } else {
        DebugLog(@"Error starting server: %@", err);
    }
}

- (void) connectToInspector {
    DebugLog(@"Connecting to local inspector...");

    GCDAsyncSocket* newInspSock = [[GCDAsyncSocket alloc]
                                   initWithDelegate:self
                                      delegateQueue:dispatch_get_current_queue()];

    NSError *err = nil;

    if (![newInspSock connectToHost:INSPECTOR_HOST onPort:INSPECTOR_PORT error:&err]) {
        DebugLog(@"Error connecting to web inspector: %@", err);
    }
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    DebugLog(@"Incoming connection accepted");

    if (!running) return;

    [self.waitingExternalSockets addObject:newSocket];
    [self connectToInspector];
}

- (void)socket:(GCDAsyncSocket*)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    if (!running) return;

    if ([host isEqualToString:INSPECTOR_HOST] && port == INSPECTOR_PORT) {
        DebugLog(@"Connected to local inspector");

        assert(self.waitingExternalSockets.count > 0);

        GCDAsyncSocket* extSock = [self.waitingExternalSockets objectAtIndex:0];
        [self.waitingExternalSockets removeObjectAtIndex:0];

        [self.socketMap setObject:sock forKey:[NSValue valueWithNonretainedObject:extSock]];
        [self.socketMap setObject:extSock forKey:[NSValue valueWithNonretainedObject:sock]];

        [sock readDataWithTimeout:PROXYTIMEOUT tag:1];
        [extSock readDataWithTimeout:PROXYTIMEOUT tag:2];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (!running) return;
    NSData* dataCopy = [data copy];
    GCDAsyncSocket* outSock = [self.socketMap objectForKey:[NSValue valueWithNonretainedObject:sock]];
    if (outSock && [outSock isConnected]) [outSock writeData:dataCopy withTimeout:PROXYTIMEOUT tag:tag];
    [sock readDataWithTimeout:PROXYTIMEOUT tag:tag];
}

- (void)socketDidDisconnect:(GCDAsyncSocket*)sock withError:(NSError*)err {
    GCDAsyncSocket* otherSocket = [self.socketMap objectForKey:[NSValue valueWithNonretainedObject:sock]];
    [otherSocket setDelegate:nil delegateQueue:NULL];
    [otherSocket disconnectAfterWriting];
}

#pragma mark - Netservice delegate

- (void)netServiceDidPublish:(NSNetService*)sender {
    DebugLog(@"Zeroconf name advertised.");
}

- (void)netService:(NSNetService*)sender didNotPublish:(NSDictionary*)errorDict {
    DebugLog(@"Failed at advertising the service with Zeroconf. Error code: %d",
        [errorDict valueForKey:NSNetServicesErrorCode]);
}

@end
