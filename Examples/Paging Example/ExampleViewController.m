//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "ExampleViewController.h"


@interface ExampleViewController () <SwipeViewDataSource, SwipeViewDelegate>

@property (nonatomic, weak) IBOutlet SwipeView *swipeView;
@property (nonatomic, strong) NSMutableArray *items;

@end


@implementation ExampleViewController
{
    NSArray *types;
}

- (void)dealloc
{
    //it's a good idea to set these to nil here to avoid
    //sending messages to a deallocated viewcontroller
    //this is true even if your project is using ARC, unless
    //you are targeting iOS 5 as a minimum deployment target
    _swipeView.delegate = nil;
    _swipeView.dataSource = nil;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.items = [NSMutableArray array];
    for (int i = 0; i < 100; i++)
    {
        [_items addObject:@(i)];
    }
    types = @[@(YES), @(NO), @(YES), @(NO), @(YES), @(NO), @(YES), @(NO), @(YES), @(NO), @(YES), @(NO)];
    //configure swipeView
    _swipeView.pagingEnabled = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark iCarousel methods

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    //return the total number of items in the carousel
    return [types count];
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index
{
    BOOL type = [types[index] boolValue];
    UIView *view = [swipeView dequeueReusableViewWithIdentifier:type?@"YES":@"NO"];
    if (view == nil)
    {
        NSLog(@"can not found reusabledView");
    }
    UILabel *label = nil;
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        //don't do anything specific to the index within
        //this `if (view == nil) {...}` statement because the view will be
        //recycled and used with other index values later
        view = [[UIView alloc] initWithFrame:self.swipeView.bounds];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        label = [[UILabel alloc] initWithFrame:view.bounds];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [label.font fontWithSize:50];
        label.tag = 1;
        [view addSubview:label];
        
        [view setSwipeViewReseIdentifier:type?@"YES":@"NO"];
        
        view.backgroundColor = type?[UIColor purpleColor]:[UIColor lightGrayColor];
    }
    else
    {
        //get a reference to the label in the recycled view
        label = (UILabel *)[view viewWithTag:1];
    }
    
    return view;
}

//if you don`t implement 'swipeViewItemSize' protocol, SwipeView uses its size as item view size.
/*
- (CGSize)swipeViewItemSize:(SwipeView *)swipeView
{
    return self.swipeView.bounds.size;
}
 */
- (IBAction)clearSwipeViewCache:(id)sender {
    [self.swipeView releaseResuableView];
}
- (IBAction)reload:(id)sender {
    [self.swipeView reloadData];
}

@end
