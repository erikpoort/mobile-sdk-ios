/*   Copyright 2013 APPNEXUS INC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "UIView+ANCategory.h"
#import "ANLogging.h"

#import "ANGlobal.h"

@implementation UIView (ANCategory)

- (void)an_presentView:(UIView *)view animated:(BOOL)animated
{
	[self an_presentView:view animated:animated completion:NULL];
}

- (void)an_presentView:(UIView *)view animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
	view.transform = CGAffineTransformMakeTranslation(0, self.bounds.size.height);
	
	NSTimeInterval animationDuration = animated ? kAppNexusAnimationDuration : 0.0;
	
	[UIView animateWithDuration:animationDuration
					 animations:^{
						 [self addSubview:view];
						 view.transform = CGAffineTransformMakeTranslation(0, 0);
					 }
					 completion:completion];
}

- (void)an_dismissFromPresentingViewAnimated:(BOOL)animated
{
	NSTimeInterval animationDuration = animated ? kAppNexusAnimationDuration : 0.0;

	[UIView animateWithDuration:animationDuration
                     animations:^{
                         self.transform = CGAffineTransformMakeTranslation(0, self.bounds.size.height);
                     }
                     completion:^(BOOL finished) {
                         [self removeFromSuperview];
                     }];
}

- (void)an_removeSubviews {
    for (UIView *view in [self subviews]) {
        if ([view respondsToSelector:@selector(removeFromSuperview)]) {
            [view performSelector:@selector(removeFromSuperview)];
        }
    }
}

- (void)an_removeSubviewsWithException:(UIView *)exception {
    for (UIView *view in self.subviews) {
        if (view != exception) {
            if ([view isKindOfClass:[WKWebView class]]) {
                WKWebView *webView = (WKWebView *)view;
                [webView stopLoading];
                [webView setNavigationDelegate:nil];
                [webView setUIDelegate:nil];
            }
            [view an_removeSubviews];
            [view removeFromSuperview];
        }
    }

}

- (BOOL)an_isViewable {
    BOOL isHidden = self.hidden;
    if (isHidden) return NO;
    
    BOOL isAttachedToWindow = self.window ? YES : NO;
    if (!isAttachedToWindow) return NO;
    
    BOOL isInHiddenSuperview = NO;
    UIView *ancestorView = self.superview;
    while (ancestorView) {
        if (ancestorView.hidden) {
            isInHiddenSuperview = YES;
            break;
        }
        ancestorView = ancestorView.superview;
    }
    if (isInHiddenSuperview) return NO;
    
    CGRect screenRect = [UIScreen mainScreen].bounds;
    CGRect normalizedSelfRect = [self convertRect:self.bounds toView:nil];
    return CGRectIntersectsRect(normalizedSelfRect, screenRect);
}

- (BOOL)an_isAtLeastHalfViewable {
    BOOL isHidden = self.hidden;
    if (isHidden) return NO;
    
    BOOL isAttachedToWindow = self.window ? YES : NO;
    if (!isAttachedToWindow) return NO;
    
    BOOL isInHiddenSuperview = NO;
    UIView *ancestorView = self.superview;
    while (ancestorView) {
        if (ancestorView.hidden) {
            isInHiddenSuperview = YES;
            break;
        }
        ancestorView = ancestorView.superview;
    }
    if (isInHiddenSuperview) return NO;
    
    CGRect screenRect = [UIScreen mainScreen].bounds;
    CGRect normalizedSelfRect = [self convertRect:self.bounds toView:nil];
    CGRect intersection = CGRectIntersection(screenRect, normalizedSelfRect);
    if (CGRectEqualToRect(intersection, CGRectNull)) {
        return NO;
    }
    
    CGFloat intersectionArea = CGRectGetWidth(intersection) * CGRectGetHeight(intersection);
    CGFloat selfArea = CGRectGetWidth(normalizedSelfRect) * CGRectGetHeight(normalizedSelfRect);
    return intersectionArea >= 0.5 * selfArea;
}

- (CGFloat)an_exposedPercentage{
    CGFloat exposedPrecentage = 0;
    if(self.an_isViewable){
        CGRect normalizedSelfRect = [self convertRect:self.bounds toView:nil];
        CGRect intersection = CGRectIntersection(UIScreen.mainScreen.bounds, normalizedSelfRect);
        CGFloat intersectionArea = intersection.size.width  * intersection.size.height;
        int totalArea = normalizedSelfRect.size.width *normalizedSelfRect.size.height;
        exposedPrecentage  = (intersectionArea * 100)/(totalArea);
    }
    return exposedPrecentage;
}

//Provide a visible rectangle in more of the position within the view along with the width & height.eg (81.0,430.0,300.0,250.0)
- (CGRect)an_visibleInViewRectangle{
    CGRect visibleRectangle =  CGRectMake(0,0,0,0);
    if(self.an_isViewable){
    
        UIWindow *parentWindow = self.window;
    
        // We need to call convertRect:toView: on this view's superview rather than on this view itself.
        CGRect viewFrameInWindowCoordinates = [self.superview convertRect:self.frame toView:parentWindow];
        visibleRectangle = CGRectIntersection(viewFrameInWindowCoordinates, parentWindow.frame);

    }
    
    return visibleRectangle;
    
}

- (CGRect)an_visibleRectangle{
    CGRect visibleRectangle =  CGRectMake(0,0,0,0);
    if(self.an_isViewable){
        CGRect normalizedSelfRect = [self convertRect:self.bounds toView:nil];
        CGRect intersection = CGRectIntersection(UIScreen.mainScreen.bounds, normalizedSelfRect);
        CGFloat visibleRectangleX = 0.0;
        CGFloat visibleRectangleY = 0.0;
        
        if(normalizedSelfRect.origin.x < 0 )
        {
            // The view is partly hidden from the left.(The view has scrolled out to the left and part of it is outside of screen bounds)
            visibleRectangleX =  -1 * normalizedSelfRect.origin.x;
        }else if( (normalizedSelfRect.origin.x + normalizedSelfRect.size.width) > UIScreen.mainScreen.bounds.size.width){
            // Starting X of the View + its width is greater than the screen Width.
            // The view extends into the right of the screen and only partially visible.(The view has scrolled out to the right and part of it is outside of screen bounds)
            visibleRectangleX =  0;
        }else if(normalizedSelfRect.origin.y < 0){
            // The view has scrolled up
            visibleRectangleY =  -1 * normalizedSelfRect.origin.y;
        }else  if((normalizedSelfRect.origin.y + normalizedSelfRect.size.height) > UIScreen.mainScreen.bounds.size.height){
            // Starting Y of the View + its height is greater than the screen height.
            // The view has scrolled down
            visibleRectangleY = 0;
        }
        visibleRectangle = CGRectMake(visibleRectangleX, visibleRectangleY, intersection.size.width, intersection.size.height);
    }
    return visibleRectangle;
}

- (UIViewController *)an_parentViewController {
    UIResponder *responder = self;
    
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    
    return nil;    
}

- (CGRect)an_originalFrame {
    CGAffineTransform currentTransform = self.transform;
    self.transform = CGAffineTransformIdentity;
    CGRect originalFrame = self.frame;
    self.transform = currentTransform;

    return originalFrame;
}

#pragma mark - Autolayout

- (void)an_constrainWithFrameSize {
    [self an_constrainWithSize:self.frame.size];
}

- (void)an_constrainWithSize:(CGSize)size {
    [self an_removeSizeConstraintToSuperview];
    
    NSLayoutConstraint *widthConstraint;
    NSLayoutConstraint *heightConstraint;
    
    [self an_extractWidthConstraint:&widthConstraint
                   heightConstraint:&heightConstraint];

    if (size.width > 1) {
        if (!widthConstraint) {
            widthConstraint = [NSLayoutConstraint constraintWithItem:self
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:nil
                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                          multiplier:1
                                                            constant:size.width];
            [self addConstraint:widthConstraint];
        } else {
            widthConstraint.constant = size.width;
        }
    } else {
        // Dynamic width - fill width of superview
        if (widthConstraint) {
            [self removeConstraint:widthConstraint];
        }
        if (self.superview) {
            NSLayoutConstraint *superviewWidthConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                                        attribute:NSLayoutAttributeWidth
                                                                                        relatedBy:NSLayoutRelationEqual
                                                                                           toItem:self.superview
                                                                                        attribute:NSLayoutAttributeWidth
                                                                                       multiplier:1
                                                                                         constant:0];
            [self.superview addConstraint:superviewWidthConstraint];
        } else {
            ANLogError(@"Failed to properly size dynamic width content view %@ to superview, as superview is nil", self);
            // It's impossible to know what the right width to use here is because the width is supposed to be flexible.
            // But adding a constant to minimize any issue and hopefully this error rectifies itself when the view is actually displayed.
            widthConstraint = [NSLayoutConstraint constraintWithItem:self
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:nil
                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                          multiplier:1
                                                            constant:320];
            [self addConstraint:widthConstraint];
        }
    }

    if (!heightConstraint) {
        heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1
                                                         constant:size.height];
        [self addConstraint:heightConstraint];
    } else {
        heightConstraint.constant = size.height;
    }
}

- (void)an_constrainToSizeOfSuperview {
    [self an_removeSizeConstraintToSuperview];
    [self an_removeSizeConstraint];
    
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.superview
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1
                                                                        constant:0];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.superview
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1
                                                                         constant:0];
    [self.superview addConstraints:@[widthConstraint, heightConstraint]];
}

- (void)an_constrainToSizeOfSuperviewApplyingSafeAreaLayoutGuide {
    [self an_removeSizeConstraintToSuperview];
    [self an_removeSizeConstraint];
    NSLayoutConstraint *widthConstraint;
    NSLayoutConstraint *heightConstraint;
    if (@available(iOS 11.0, *)) {
        widthConstraint = [NSLayoutConstraint constraintWithItem:self
                                                       attribute:NSLayoutAttributeWidth
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:self.superview.safeAreaLayoutGuide
                                                       attribute:NSLayoutAttributeWidth
                                                      multiplier:1
                                                        constant:0];
        heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.superview.safeAreaLayoutGuide
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1
                                                         constant:0];
    }
    else
    {
        widthConstraint = [NSLayoutConstraint constraintWithItem:self
                                                       attribute:NSLayoutAttributeWidth
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:self.superview
                                                       attribute:NSLayoutAttributeWidth
                                                      multiplier:1
                                                        constant:0];
        heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.superview
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1
                                                         constant:0];
    }
    [self.superview addConstraints:@[widthConstraint, heightConstraint]];
}

- (void)an_alignToSuperviewWithXAttribute:(NSLayoutAttribute)xAttribute
                               yAttribute:(NSLayoutAttribute)yAttribute {
    [self an_alignToSuperviewWithXAttribute:xAttribute
                                 yAttribute:yAttribute
                                    offsetX:0
                                    offsetY:0];
}

- (void)an_alignToSuperviewWithXAttribute:(NSLayoutAttribute)xAttribute
                               yAttribute:(NSLayoutAttribute)yAttribute
                                  offsetX:(CGFloat)offsetX
                                  offsetY:(CGFloat)offsetY {
    [self an_removeAlignmentConstraintsToSuperview];
    
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                   attribute:xAttribute
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.superview
                                                                   attribute:xAttribute
                                                                  multiplier:1
                                                                    constant:offsetX];
    NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                   attribute:yAttribute
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.superview
                                                                   attribute:yAttribute
                                                                  multiplier:1
                                                                    constant:offsetY];
    [self.superview addConstraints:@[xConstraint, yConstraint]];
}

- (void)an_alignToSuperviewApplyingSafeAreaLayoutGuideWithXAttribute:(NSLayoutAttribute)xAttribute
                                       yAttribute:(NSLayoutAttribute)yAttribute
                                          offsetX:(CGFloat)offsetX
                                          offsetY:(CGFloat)offsetY {
    [self an_removeAlignmentConstraintsToSuperview];
    NSLayoutConstraint *  yConstraint;
    NSLayoutConstraint *xConstraint;
    if (@available(iOS 11.0, *)) {
        yConstraint = [NSLayoutConstraint constraintWithItem:self
                                                   attribute:yAttribute
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self.superview.safeAreaLayoutGuide
                                                   attribute:yAttribute
                                                  multiplier:1
                                                    constant:offsetY];
        xConstraint = [NSLayoutConstraint constraintWithItem:self
                                                   attribute:xAttribute
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self.superview.safeAreaLayoutGuide
                                                   attribute:xAttribute
                                                  multiplier:1
                                                    constant:offsetX];
    }
    else
    {    yConstraint = [NSLayoutConstraint constraintWithItem:self
                                                    attribute:yAttribute
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:self.superview
                                                    attribute:yAttribute
                                                   multiplier:1
                                                     constant:offsetY];
        xConstraint = [NSLayoutConstraint constraintWithItem:self
                                                   attribute:xAttribute
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self.superview
                                                   attribute:xAttribute
                                                  multiplier:1
                                                    constant:offsetX];}
    [self.superview addConstraints:@[xConstraint, yConstraint]];
}

- (void)an_removeSizeConstraintToSuperview {
    NSArray *superviewConstraintsCopy = [self.superview.constraints copy];
    [superviewConstraintsCopy enumerateObjectsUsingBlock:^(NSLayoutConstraint *existingConstraint, NSUInteger idx, BOOL *stop) {
        BOOL firstItemSelfSecondItemSuperview = existingConstraint.firstItem == self && existingConstraint.secondItem == self.superview;
        BOOL firstItemSuperviewSecondItemSelf = existingConstraint.firstItem == self.superview && existingConstraint.secondItem == self;
        BOOL attributesEqual = existingConstraint.firstAttribute == existingConstraint.secondAttribute;
        BOOL isWidthOrHeightConstraint = existingConstraint.firstAttribute == NSLayoutAttributeWidth || existingConstraint.firstAttribute == NSLayoutAttributeHeight;
        BOOL invalidConstraint = (firstItemSelfSecondItemSuperview || firstItemSuperviewSecondItemSelf) && attributesEqual && isWidthOrHeightConstraint;
        if (invalidConstraint) {
            [self.superview removeConstraint:existingConstraint];
        }
    }];
}

- (void)an_removeAlignmentConstraintsToSuperview {
    NSArray *superviewConstraintsCopy = [self.superview.constraints copy];
    [superviewConstraintsCopy enumerateObjectsUsingBlock:^(NSLayoutConstraint *existingConstraint, NSUInteger idx, BOOL *stop) {
        BOOL firstItemSelfSecondItemSuperview = existingConstraint.firstItem == self && existingConstraint.secondItem == self.superview;
        BOOL firstItemSuperviewSecondItemSelf = existingConstraint.firstItem == self.superview && existingConstraint.secondItem == self;
        BOOL attributesEqual = existingConstraint.firstAttribute == existingConstraint.secondAttribute;
        BOOL isWidthOrHeightConstraint = existingConstraint.firstAttribute == NSLayoutAttributeWidth || existingConstraint.firstAttribute == NSLayoutAttributeHeight;
        BOOL invalidConstraint = (firstItemSelfSecondItemSuperview || firstItemSuperviewSecondItemSelf) && attributesEqual && !isWidthOrHeightConstraint;
        if (invalidConstraint) {
            [self.superview removeConstraint:existingConstraint];
        }
    }];
}

- (void)an_removeSizeConstraint {
    NSLayoutConstraint *widthConstraint;
    NSLayoutConstraint *heightConstraint;
    [self an_extractWidthConstraint:&widthConstraint
                   heightConstraint:&heightConstraint];
    
    if (widthConstraint) {
        [self removeConstraint:widthConstraint];
    }
    if (heightConstraint) {
        [self removeConstraint:heightConstraint];
    }
}

- (void)an_extractWidthConstraint:(NSLayoutConstraint * __autoreleasing *)widthConstraint
                 heightConstraint:(NSLayoutConstraint * __autoreleasing *)heightConstraint {
    [self.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *existingConstraint, NSUInteger idx, BOOL *stop) {
        BOOL constraintOnlyOnSelf = existingConstraint.firstItem == self && existingConstraint.secondAttribute == NSLayoutAttributeNotAnAttribute && existingConstraint.secondItem == nil;
        BOOL constraintIsWidthConstraint = existingConstraint.firstAttribute == NSLayoutAttributeWidth && constraintOnlyOnSelf;
        BOOL constraintIsHeightConstraint = existingConstraint.firstAttribute == NSLayoutAttributeHeight && constraintOnlyOnSelf;
        if (constraintIsWidthConstraint) {
            *widthConstraint = existingConstraint;
        }
        if (constraintIsHeightConstraint) {
            *heightConstraint = existingConstraint;
        }
    }];
}

@end
