//
//  SwipeView.m
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


#import "SwipeView.h"
#import <objc/message.h>


#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma GCC diagnostic ignored "-Wreceiver-is-weak"
#pragma GCC diagnostic ignored "-Wconversion"
#pragma GCC diagnostic ignored "-Wselector"
#pragma GCC diagnostic ignored "-Wgnu"


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


@interface SwipeView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<NSValue *> *itemFrames;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIView *> *usingViews;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet *> *cachedViews;

@end


@implementation SwipeView

#pragma mark -
#pragma mark Initialisation

- (void)setUp
{
    _scrollEnabled = YES;
    _pagingEnabled = YES;
    _delaysContentTouches = YES;
    _bounces = YES;
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 300, 60)];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _scrollView.autoresizesSubviews = YES;
    _scrollView.delegate = self;
    _scrollView.delaysContentTouches = _delaysContentTouches;
    _scrollView.pagingEnabled = NO;
    _scrollView.scrollEnabled = _scrollEnabled;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.scrollsToTop = NO;
    _scrollView.clipsToBounds = NO;
    _scrollView.decelerationRate = 0;
    
    _currentItemIndex = 0;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    tapGesture.delegate = self;
    [_scrollView addGestureRecognizer:tapGesture];
    
    self.clipsToBounds = YES;
    
    //place scrollview at bottom of hierarchy
    [self insertSubview:_scrollView atIndex:0];
    
    _usingViews = [NSMutableDictionary dictionaryWithCapacity:8];
    _cachedViews = [NSMutableDictionary dictionaryWithCapacity:8];
    _itemFrames = [NSMutableArray arrayWithCapacity:8];
    
    [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setUp];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setUp];
    }
    return self;
}

- (void)dealloc
{
    [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)setDataSource:(id<SwipeViewDataSource>)dataSource
{
    _dataSource = dataSource;
    [self reloadData];
}

- (void)setDelegate:(id<SwipeViewDelegate>)delegate
{
    _delegate = delegate;
    [self reloadData];
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    _scrollEnabled = scrollEnabled;
    _scrollView.scrollEnabled = _scrollEnabled;
}

- (void)setPagingEnabled:(BOOL)pagingEnabled
{
    _pagingEnabled = pagingEnabled;
    if (pagingEnabled)
        [self reloadData];
}

- (void)setDelaysContentTouches:(BOOL)delaysContentTouches
{
    _delaysContentTouches = delaysContentTouches;
    _scrollView.delaysContentTouches = delaysContentTouches;
}

- (void)setBounces:(BOOL)bounces
{
    if (_bounces != bounces)
    {
        _bounces = bounces;
        _scrollView.alwaysBounceHorizontal = NO;
        _scrollView.alwaysBounceVertical = NO;
    }
}

- (BOOL)isDragging
{
    return _scrollView.dragging;
}

- (BOOL)isDecelerating
{
    return _scrollView.decelerating;
}

#pragma mark -
#pragma mark View management

- (NSArray *)indexesForVisibleItems
{
    return [[_usingViews allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)visibleItemViews
{
    return [_usingViews allValues];
}

- (UIView *)itemViewAtIndex:(NSInteger)index
{
    return _usingViews[@(index)];
}

- (UIView *)currentItemView
{
    if (_currentItemIndex < 0) return nil;
    return [self itemViewAtIndex:_currentItemIndex];
}

- (NSInteger)indexOfItemView:(UIView *)view
{
    NSUInteger index = [[_usingViews allValues] indexOfObject:view];
    if (index != NSNotFound)
    {
        return [[_usingViews allKeys][index] integerValue];
    }
    return NSNotFound;
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
{
    _edgeInsets = edgeInsets;
}

#pragma mark -
#pragma mark View layout


- (void)layoutSubviews
{
    [super layoutSubviews];
    [self reloadData];
    
    _scrollView.frame = self.bounds;
}

#pragma mark -
#pragma mark View queing

- (void)queueItemView:(UIView *)view
{
    NSString *resuIdentifier = [view swipeViewReseIdentifier];
    
    if (resuIdentifier)
    {
        NSMutableSet *set = _cachedViews[resuIdentifier];
        if (!set)
        {
            set = [NSMutableSet set];
            _cachedViews[resuIdentifier] = set;
        }
        [set addObject:view];
    }
}

- (UIView *)dequeueReusableViewWithIdentifier:(NSString *)identifier
{
    UIView *view = nil;
    
    if (identifier != nil)
    {
        NSMutableSet *set = _cachedViews[identifier];
        if (set != nil)
        {
            view = [set anyObject];
            
            if (view != nil)
            {
                [set removeObject:view];
            }
        }
    }
    return view;
}

- (void)releaseResuableView
{
    [_cachedViews removeAllObjects];
}

#pragma mark -
#pragma mark View loading

- (void)reloadData
{
    //remove old views
    {
        NSArray<UIView *> *views = [_usingViews allValues];
        [views makeObjectsPerformSelector:@selector(removeFromSuperview)];
        for (UIView *view in views)
            [self queueItemView:view];
        [_usingViews removeAllObjects];
    }
    [_itemFrames removeAllObjects];
    
    _itemCount = [_dataSource numberOfItemsInSwipeView:self];
    
    CGFloat contentWidth = _edgeInsets.left + _edgeInsets.right;
    
    CGRect itemFrame = CGRectMake(_edgeInsets.left, _edgeInsets.top, 0, self.frame.size.height - _edgeInsets.top - _edgeInsets.bottom);
    BOOL useDefaultSize = ![_delegate respondsToSelector:@selector(swipeView:widthForItem:)];
    if (!useDefaultSize) {
        for (NSInteger i = 0; i < _itemCount; i++) {
            CGFloat width = [_delegate swipeView:self widthForItem:i];
            contentWidth += width;

            itemFrame.size.width = width;
            [_itemFrames addObject:[NSValue valueWithCGRect:itemFrame]];
            itemFrame.origin.x += width;
            itemFrame.origin.x += _separatorWidth;
        }
    } else {
        contentWidth += _itemWidth * _itemCount;
        for (NSInteger i = 0; i < _itemCount; i++) {
            itemFrame.size.width = _itemWidth;
            [_itemFrames addObject:[NSValue valueWithCGRect:itemFrame]];
            itemFrame.origin.x += _itemWidth;
            itemFrame.origin.x += _separatorWidth;
        }
    }
    if (_itemCount) {
        contentWidth += _separatorWidth * (_itemCount - 1);
    }
    _scrollView.contentSize = CGSizeMake(contentWidth, self.bounds.size.height);
        
    [self layoutItemView];
}

- (void)layoutItemView
{
    CGFloat left = _scrollView.contentOffset.x;
    CGFloat right = _scrollView.contentOffset.x + self.bounds.size.width;
    
    NSInteger minIndex = -1;
    NSInteger maxIndex = -1;
    
    if (right > _scrollView.contentSize.width) right = _scrollView.contentSize.width;
    
    for (NSInteger i = 0; i < _itemCount; i++) {
        NSValue *value = _itemFrames[i];
        CGRect itemFrame = [value CGRectValue];

        if (left <= CGRectGetMaxX(itemFrame) && minIndex < 0) {
            minIndex = i;
        }
    }
    for (NSInteger i = _itemCount - 1; i >= 0; i--) {
        NSValue *value = _itemFrames[i];
        CGRect itemFrame = [value CGRectValue];
        
        if (right >= itemFrame.origin.x && maxIndex < 0) {
            maxIndex = i;
        }
    }
    
    //  最左边一个作为当前条目
    _currentItemIndex = minIndex;
    
    
    NSArray<NSNumber *> *existedViewIndexs = [[_usingViews allKeys] sortedArrayUsingSelector:@selector(compare:)];
    BOOL existsView = existedViewIndexs.count > 0;
    NSInteger existedFirstIndex = existsView ? existedViewIndexs.firstObject.integerValue : INT_MAX;
    NSInteger existedLastIndex = existsView ? existedViewIndexs.lastObject.integerValue : -1;
    
    BOOL noTree = NO;
    if (minIndex < 0 || maxIndex < 0 || maxIndex < minIndex) {
        noTree = YES;
    }
    if (noTree) {
        
        for (NSInteger i = existedFirstIndex; i <= existedLastIndex; i++) {
            UIView *view = _usingViews[@(i)];
            _usingViews[@(i)] = nil;
            [view removeFromSuperview];
            [self queueItemView:view];
        }
    } else {
        
        for (NSInteger i = existedFirstIndex; i < minIndex; i++) {
            UIView *view = _usingViews[@(i)];
            _usingViews[@(i)] = nil;
            [view removeFromSuperview];
            [self queueItemView:view];
        }
        
        for (NSInteger i = maxIndex + 1; i <= existedLastIndex; i++) {
            UIView *view = _usingViews[@(i)];
            _usingViews[@(i)] = nil;
            [view removeFromSuperview];
            [self queueItemView:view];
        }

        for (NSInteger i = minIndex; i <= maxIndex; i++) {
            UIView *view = _usingViews[@(i)];
            if (!view) {
                view = [self.dataSource swipeView:self viewForItemAtIndex:i];
                _usingViews[@(i)] = view;
            }
            view.frame = [_itemFrames[i] CGRectValue];
            [_scrollView addSubview:view];
        }
    }
}

- (void)scrollToRecentByPageEnable
{
    if (!_pagingEnabled) return;
    if (self.isDecelerating) return;
    
    // 离中心线最近的Item
    NSInteger index = -1;
    CGFloat middle = _scrollView.contentOffset.x + self.bounds.size.width / 2;
    for (NSInteger i = 0; i < _itemCount; i ++) {
        
        CGFloat x = CGRectGetMidX(_itemFrames[i].CGRectValue);
        
        index = i;
        if (middle <= x) break;
    }
    if (index < 0) return;
    if (index > 0) {
        
        CGFloat prevX = CGRectGetMidX(_itemFrames[index - 1].CGRectValue);
        CGFloat currX = CGRectGetMidX(_itemFrames[index].CGRectValue);
        
        index = (fabs(prevX - middle) < fabs(currX - middle)) ? (index - 1) : index;
    }
    [self scrollToItemAtIndex:index];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self reloadData];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self layoutItemView];
    }
}

- (UIView *)hitxTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return nil;
    UIView *view = [super hitTest:point withEvent:event];
    if ([view isEqual:self])
    {
        for (UIView *subview in _scrollView.subviews)
        {
            CGPoint offset = CGPointMake(point.x - _scrollView.frame.origin.x + _scrollView.contentOffset.x - subview.frame.origin.x,
                                         point.y - _scrollView.frame.origin.y + _scrollView.contentOffset.y - subview.frame.origin.y);
            
            if ((view = [subview hitTest:offset withEvent:event]))
            {
                return view;
            }
        }
        return _scrollView;
    }
    return view;
}

#pragma mark -
#pragma mark Gestures and taps

- (NSInteger)viewOrSuperviewIndex:(UIView *)view
{
    if (view == nil || view == _scrollView)
    {
        return NSNotFound;
    }
    NSInteger index = [self indexOfItemView:view];
    if (index == NSNotFound)
    {
        return [self viewOrSuperviewIndex:view.superview];
    }
    return index;
}

- (BOOL)viewOrSuperviewHandlesTouches:(UIView *)view
{
    //thanks to @mattjgalloway and @shaps for idea
    //https://gist.github.com/mattjgalloway/6279363
    //https://gist.github.com/shaps80/6279008
    
    Class class = [view class];
    while (class && class != [UIView class])
    {
        unsigned int numberOfMethods;
        Method *methods = class_copyMethodList(class, &numberOfMethods);
        for (unsigned int i = 0; i < numberOfMethods; i++)
        {
            if (method_getName(methods[i]) == @selector(touchesBegan:withEvent:))
            {
                free(methods);
                return YES;
            }
        }
        if (methods) free(methods);
        class = [class superclass];
    }
    
    if (view.superview && view.superview != _scrollView)
    {
        return [self viewOrSuperviewHandlesTouches:view.superview];
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch
{
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]])
    {
        //handle tap
        NSInteger index = [self viewOrSuperviewIndex:touch.view];
        if (index != NSNotFound)
        {
            if ((_delegate && ![_delegate swipeView:self shouldSelectItemAtIndex:index]) ||
                [self viewOrSuperviewHandlesTouches:touch.view])
            {
                return NO;
            }
            else
            {
                return YES;
            }
        }
    }
    return NO;
}

- (void)didTap:(UITapGestureRecognizer *)tapGesture
{
    /*
    CGPoint point = [tapGesture locationInView:_scrollView];
    NSInteger index = _vertical? (point.y / (_itemSize.height)): (point.x / (_itemSize.width));
    if (_wrapEnabled)
    {
        index = index % _numberOfItems;
    }
    if (index >= 0 && index < _numberOfItems)
    {
        [_delegate swipeView:self didSelectItemAtIndex:index];
    }
     */
}


#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(__unused UIScrollView *)scrollView
{
}

- (void)scrollViewWillBeginDragging:(__unused UIScrollView *)scrollView
{
    if ([_delegate respondsToSelector:@selector(swipeViewWillBeginDragging:)])
        [_delegate swipeViewWillBeginDragging:self];
    
}

- (void)scrollViewDidEndDragging:(__unused UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([_delegate respondsToSelector:@selector(swipeViewDidEndDragging:willDecelerate:)])
        [_delegate swipeViewDidEndDragging:self willDecelerate:decelerate];
    
    if (!decelerate) {
        [self scrollToRecentByPageEnable];
    }
}

- (void)scrollViewWillBeginDecelerating:(__unused UIScrollView *)scrollView
{
    if ([_delegate respondsToSelector:@selector(swipeViewWillBeginDecelerating:)])
        [_delegate swipeViewWillBeginDecelerating:self];
}

- (void)scrollViewDidEndDecelerating:(__unused UIScrollView *)scrollView
{
    
    if ([_delegate respondsToSelector:@selector(swipeViewDidEndDecelerating:)])
        [_delegate swipeViewDidEndDecelerating:self];
    
    [self scrollToRecentByPageEnable];
}

- (void)scrollToItemAtIndex:(NSInteger)index
{
    CGRect goalRect = _itemFrames[index].CGRectValue;
    CGFloat border = (self.bounds.size.width - goalRect.size.width) / 2;
    goalRect.origin.x -= border;
    goalRect.size.width += border * 2;
    
    [_scrollView scrollRectToVisible:goalRect animated:YES];
}

@end

#import <objc/runtime.h>

@implementation UIView (SwipeViewIdentifier)

- (void)setSwipeViewReseIdentifier:(NSString *)identifer
{
    objc_setAssociatedObject(self, "SwipeViewResuKey", identifer, OBJC_ASSOCIATION_COPY);
}

- (NSString *)swipeViewReseIdentifier
{
    return objc_getAssociatedObject(self, "SwipeViewResuKey");
}
@end
