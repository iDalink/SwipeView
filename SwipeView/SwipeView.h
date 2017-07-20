//
//  SwipeView.h
//
//  Version 1.3.2
//
//  Created by Nick Lockwood on 03/09/2010.
//  Copyright 2010 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version of SwipeView from here:
//
//  https://github.com/nicklockwood/SwipeView
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wauto-import"
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"


#import <Availability.h>
#undef weak_delegate
#if __has_feature(objc_arc) && __has_feature(objc_arc_weak)
#define weak_delegate weak
#else
#define weak_delegate unsafe_unretained
#endif


#import <UIKit/UIKit.h>


@protocol SwipeViewDataSource, SwipeViewDelegate;

@interface SwipeView : UIView

@property (nonatomic, weak_delegate) id<SwipeViewDataSource> dataSource;
@property (nonatomic, weak_delegate) id<SwipeViewDelegate> delegate;

@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, strong, readonly) NSArray *indexesForVisibleItems;
@property (nonatomic, strong, readonly) NSArray *visibleItemViews;
@property (nonatomic, strong, readonly) UIView *currentItemView;
@property (nonatomic, assign, readonly) NSInteger currentItemIndex;
@property (nonatomic, assign, readonly) NSInteger itemCount;
@property (nonatomic, assign, getter = isPagingEnabled) BOOL pagingEnabled;
@property (nonatomic, assign, getter = isScrollEnabled) BOOL scrollEnabled;
@property (nonatomic, assign) BOOL delaysContentTouches;
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, readonly, getter = isDragging) BOOL dragging;
@property (nonatomic, readonly, getter = isDecelerating) BOOL decelerating;
@property (nonatomic, assign) UIEdgeInsets edgeInsets;
@property (nonatomic, assign) CGFloat separatorWidth;

- (void)reloadData;
- (void)scrollToItemAtIndex:(NSInteger)index;
- (UIView *)itemViewAtIndex:(NSInteger)index;
- (NSInteger)indexOfItemView:(UIView *)view;

- (UIView *)dequeueReusableViewWithIdentifier:(NSString *)identifier;

- (void)releaseResuableView;
@end


@protocol SwipeViewDataSource <NSObject>

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView;
- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index;

@end


@protocol SwipeViewDelegate <NSObject>
@optional

- (CGFloat)swipeView:(SwipeView *)swipeView widthForItem:(NSInteger)index;
- (void)swipeViewDidScroll:(SwipeView *)swipeView;
- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView;
- (void)swipeViewWillBeginDragging:(SwipeView *)swipeView;
- (void)swipeViewDidEndDragging:(SwipeView *)swipeView willDecelerate:(BOOL)decelerate;
- (void)swipeViewWillBeginDecelerating:(SwipeView *)swipeView;
- (void)swipeViewDidEndDecelerating:(SwipeView *)swipeView;
- (void)swipeViewDidEndScrollingAnimation:(SwipeView *)swipeView;
- (BOOL)swipeView:(SwipeView *)swipeView shouldSelectItemAtIndex:(NSInteger)index;
- (void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index;

@end

@interface UIView (SwipeViewIdentifier)

- (void)setSwipeViewReseIdentifier:(NSString *)identifer;
- (NSString *)swipeViewReseIdentifier;
@end
#pragma GCC diagnostic pop

