//
//  GalleryViewController.m
//  SwipeViewExample
//
//  Created by liuyu on 16/1/5.
//
//

#import "CardViewController.h"
#import "SwipeView.h"

@interface CardViewController () <SwipeViewDataSource, SwipeViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *scrollIndexTextField;

@property (nonatomic, weak) IBOutlet SwipeView *swipeView;
@property (nonatomic, strong) NSMutableArray *items;
@end

@implementation CardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _items = [@[@"image1.jpg", @"image2.jpg", @"image3.jpg", @"image4.jpg", @"image5.jpg", @"image1.jpg", @"image2.jpg", @"image3.jpg", @"image4.jpg", @"image5.jpg"] mutableCopy];
    _swipeView.separatorWidth = 20;
    _swipeView.dataSource = self;
    _swipeView.delegate = self;
    _swipeView.edgeInsets = UIEdgeInsetsMake(0, 30, 0, 30);
}

- (CGFloat)swipeView:(SwipeView *)swipeView widthForItem:(NSInteger)index
{
    return 180;
}

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    //return the total number of items in the carousel
    return [_items count];
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index
{
    UIImageView *view = (UIImageView *)[swipeView dequeueReusableViewWithIdentifier:@"Identifier"];
    if (view == nil)
    {
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, swipeView.bounds.size.height * 3/2 + 20, swipeView.bounds.size.height)];
        
        view.layer.borderColor = [UIColor redColor].CGColor;
        view.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        
        view.tag = 1;
        
        [view setSwipeViewReseIdentifier:@"Identifier"];
    }
    UIImageView *imageView = (UIImageView *)[view viewWithTag:1];
    imageView.image = [UIImage imageNamed:_items[index]];
    
    return view;
}

- (CGSize)swipeViewItemSize:(SwipeView *)swipeView
{
    return CGSizeMake(swipeView.bounds.size.height * 3/2 + 20, swipeView.bounds.size.height);
}

- (IBAction)reload:(id)sender {
    [_swipeView reloadData];
}

- (IBAction)edge:(id)sender {
    UIScrollView *scrollView = [_swipeView valueForKey:@"scrollView"];
    [scrollView layoutIfNeeded];

    CGFloat x = 30;
    scrollView.contentOffset = CGPointMake(x, 0);
    scrollView.frame = scrollView.frame;
}

- (IBAction)scrollTo:(id)sender {
    NSInteger index = [self.scrollIndexTextField.text integerValue];
    [_swipeView scrollToItemAtIndex:index];
}
- (IBAction)visible:(id)sender {
    NSLog(@"visible %@  %@", _swipeView.indexesForVisibleItems, _swipeView.visibleItemViews);
}
- (IBAction)printCurrent:(id)sender {
    NSLog(@"current %ld", (long)_swipeView.currentItemIndex);
}
- (IBAction)pageOrNo:(id)sender {
    _swipeView.pagingEnabled = !_swipeView.isPagingEnabled;
}

@end
