//
//  WIPViewController.m
//  WebInspectorProxy
//
//  Created by asdasd asdasd on 6/2/12.
//  Copyright (c) 2012 asdasd. All rights reserved.
//

#import "WIPViewController.h"

@interface WIPViewController ()

@end

@implementation WIPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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

@end
