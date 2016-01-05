//
//  ListViewController.m
//  SwipeViewExample
//
//  Created by liuyu on 16/1/5.
//
//

#import "ListViewController.h"
#import "ExampleViewController.h"
#import "GalleryViewController.h"

@interface ListViewController () <UITableViewDataSource, UITableViewDelegate> {
    
    __weak IBOutlet UITableView *_tableView;
}

@end

@implementation ListViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.view = [[[NSBundle mainBundle] loadNibNamed:@"ListViewController" owner:self options:nil] lastObject];
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];

    [_tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (indexPath.row == 0) {
        cell.textLabel.text = @"视图展示，视图资源回收";
    }
    if (indexPath.row == 1) {
        cell.textLabel.text = @"小图模式展示，视图资源回收";
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        ExampleViewController *vc = [[ExampleViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (indexPath.row == 1) {
        GalleryViewController *vc = [[GalleryViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}
@end
