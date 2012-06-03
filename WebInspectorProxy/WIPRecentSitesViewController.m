#import "WIPRecentSitesViewController.h"
#import "WIPBrowserViewController.h"

@interface WIPRecentSitesViewController () {
    BOOL _persist;
}

@property (weak, nonatomic) IBOutlet UITextField *addressField;

@property (strong) NSMutableArray* recentSites;
@property (strong) NSString* recentSitesFilePath;

@end

@implementation WIPRecentSitesViewController

@synthesize addressField;
@synthesize recentSites;
@synthesize recentSitesFilePath;


- (void)awakeFromNib {
    [self setupPersistence];
    [self loadRecentSites];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidUnload {
    [self setAddressField:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger) rowOfRecentWebsite:(NSURL*)url {
    NSString* urlstr = [url description];
    NSInteger i = -1;
    for (NSDictionary* site in self.recentSites) {
        i++;
        NSString* siteurl = [site objectForKey:@"url"];
        if ([siteurl isEqualToString:urlstr]) return i;
    }
    return -1;
}

- (void) addOrSelectWebsite:(NSURL*) url {
    NSInteger row = [self rowOfRecentWebsite:url];

    if (row < 0) {
        NSDictionary* site = [NSDictionary dictionaryWithObject:[url description] forKey:@"url"];
        [self.recentSites insertObject:site atIndex:0];
        [self saveRecentSites];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        row = 0;
    }

    NSIndexPath* ipath = [NSIndexPath indexPathForRow:row inSection:0];
    [self.tableView selectRowAtIndexPath:ipath
                                animated:YES
                          scrollPosition:UITableViewScrollPositionNone];

    [self performSegueWithIdentifier:@"showWebsite" sender:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.recentSites.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"recentSitesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    NSDictionary* site = [self.recentSites objectAtIndex:(NSUInteger)indexPath.row];
    cell.textLabel.text = [[site valueForKey:@"url"] description];

    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.recentSites removeObjectAtIndex:(NSUInteger)indexPath.row];
        [self saveRecentSites];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Transitions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showWebsite"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDictionary* site = [self.recentSites objectAtIndex:(NSUInteger)indexPath.row];
        NSURL* url = [NSURL URLWithString:[site objectForKey:@"url"]];
        [[segue destinationViewController] loadWebsite:[url standardizedURL]];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - Address bar

- (IBAction)openButtonTapped:(id)sender {
    NSString* address = [self.addressField text];
    NSURL* url = [NSURL URLWithString:address];
    if (url) {
        [self addOrSelectWebsite:url];
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Malformed URL. Please fix it and try again."
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Dismiss", nil];
        [alert show];
    }
}

#pragma mark - List persistence

- (void) setupPersistence {
    _persist = YES;

    NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSFileManager* fm = [NSFileManager defaultManager];

    BOOL isDir;
    if (!([fm fileExistsAtPath:dir isDirectory:&isDir] && isDir)) {
        NSError* err = nil;
        if(![fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&err]){
            DebugLog(@"Failed to create data directory. Won't be able to persist the recent sites list.");
            DebugLog(@"The error was: %@", [err localizedDescription]);
            _persist = NO;
        }
    }

    if (_persist) self.recentSitesFilePath = [dir stringByAppendingPathComponent:@"recentSites.plist"];

}

- (void) loadRecentSites {
    self.recentSites = nil;

    if (_persist) self.recentSites = [NSMutableArray arrayWithContentsOfFile:self.recentSitesFilePath];

    if (!self.recentSites) self.recentSites = [NSMutableArray new];
}

- (void) saveRecentSites {
    if (!_persist) return;

    if(![self.recentSites writeToFile:self.recentSitesFilePath atomically:YES]){
        DebugLog(@"Failed to save recents to file %@", self.recentSitesFilePath);
    }
}

@end
