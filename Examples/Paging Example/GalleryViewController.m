//
//  GalleryViewController.m
//  SwipeViewExample
//
//  Created by liuyu on 16/1/5.
//
//

#import "GalleryViewController.h"
#import "SwipeView.h"

@interface GalleryViewController () <SwipeViewDataSource, SwipeViewDelegate>

@property (nonatomic, weak) IBOutlet SwipeView *swipeView;
@property (nonatomic, strong) NSMutableArray *items;
@end

@implementation GalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _items = [@[@"image1.jpg", @"image2.jpg", @"image3.jpg", @"image4.jpg", @"image5.jpg"] mutableCopy];
    _swipeView.dataSource = self;
    _swipeView.delegate = self;
}

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    //return the total number of items in the carousel
    return [_items count];
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index
{
    UIView *view = [swipeView dequeueReusableViewWithIdentifier:@"Identifier"];
    if (view == nil)
    {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, swipeView.bounds.size.height * 3/2 + 20, swipeView.bounds.size.height)];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, swipeView.bounds.size.height * 3/2, swipeView.bounds.size.height)];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView.backgroundColor = [UIColor clearColor];
        imageView.tag = 1;
        [view addSubview:imageView];
        
        [view setRestorationIdentifier:@"Identifier"];
    }
    UIImageView *imageView = (UIImageView *)[view viewWithTag:1];
    imageView.image = [UIImage imageNamed:_items[index]];
    
    return view;
}

- (CGSize)swipeViewItemSize:(SwipeView *)swipeView
{
    return CGSizeMake(swipeView.bounds.size.height * 3/2 + 20, swipeView.bounds.size.height);
}


@end
