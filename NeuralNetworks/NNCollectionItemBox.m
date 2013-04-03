//
//  NNHeader.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 15/05/12.
// 
// Copyright (C) 2013 Pietro Saccardi
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "NNCollectionItemBox.h"
#import "NNCollectionView.h"

@interface NNCollectionItemBox ()
- (void)updateGradients;
+ (NSColor *)baseHighlightColor;
@end

@implementation NNCollectionItemBox
@synthesize topColor=_topColor,bottomColor=_bottomColor, cornerRadius=_cornerRadius, selected=_selected, highlighted=_highlighted,delegate=_delegate,draggingPasteboardToSkip=_draggingPasteboardToSkip;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        //self.topColor=[NSColor colorWithCalibratedRed:.5 green:.48 blue:.46 alpha:.8];
        //self.bottomColor=[NSColor colorWithCalibratedRed:.27 green:.25 blue:.24 alpha:.8];
        self.topColor=[NSColor controlHighlightColor];
        self.bottomColor=[NSColor controlShadowColor];
        self.cornerRadius=8.;
    }
    
    return self;
}

- (void)setDelegate:(id<NNHeaderDraggingDelegate>)delegate
{
    if (delegate!=_delegate) {
        [self unregisterDraggedTypes];
        [self registerForDraggedTypes:[NSArray arrayWithObject:[delegate headerAllowedDraggingType:self]]];
        _delegate=delegate;
    }
}

- (id<NNHeaderDraggingDelegate>)delegate
{
    return _delegate;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    [self setHighlighted:NO];
}


- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    if (!self.delegate) return NO;
    if (self.draggingPasteboardToSkip==[sender draggingPasteboard]) return NO;
    
    [self.delegate header:self receivedData:[[sender draggingPasteboard] dataForType:[self.delegate headerAllowedDraggingType:self]]];
    return YES;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    if (!self.delegate)
        return NSDragOperationNone;
    
    if ([[sender draggingSource] isKindOfClass:[NNCollectionView class]]) {
        [(NNCollectionView *)[sender draggingSource] currentDraggingSession].animatesToStartingPositionsOnCancelOrFail=YES;
    }
    
    if (self.draggingPasteboardToSkip==[sender draggingPasteboard])
        return NSDragOperationGeneric;
    
    if (![[sender draggingPasteboard].types containsObject:[self.delegate headerAllowedDraggingType:self]])
        return NSDragOperationNone;
    
    [self setHighlighted:YES];
    
    return NSDragOperationMove;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    [self setHighlighted:NO];
    if ([[sender draggingSource] isKindOfClass:[NNCollectionView class]]) {
        [(NNCollectionView *)[sender draggingSource] currentDraggingSession].animatesToStartingPositionsOnCancelOrFail=NO;
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (highlighted!=_highlighted) {
        _highlighted=highlighted;
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)isHighlighted
{
    return _highlighted;
}

- (void)setSelected:(BOOL)selected
{
    if (selected!=_selected) {
        _selected=selected;
        [self setNeedsDisplay:YES];
    }    
}

- (BOOL)isSelected
{
    return _selected;
}

- (NSColor *)topColor
{
    return _topColor;
}

- (NSColor *)bottomColor
{
    return _bottomColor;
}

- (void)setTopColor:(NSColor *)topColor
{
    [_topColor release];
    _topColor=[topColor copy];
    [self updateGradients];
    [self setNeedsDisplay:YES];
}

+ (NSColor *)baseHighlightColor
{
    return [NSColor colorWithCalibratedRed:.411182 green:.713 blue:.384 alpha:1.];
}

- (void)updateGradients
{
    [fill release];
    [stroke release];
    
    NSColor *blendedBottom=[self.bottomColor shadowWithLevel:.4];
    NSColor *blendedTop=[self.topColor highlightWithLevel:.5];
    NSColor *highlightTop=[NNCollectionItemBox baseHighlightColor];
    NSColor *highlightBottom=[highlightTop shadowWithLevel:.4];

    
    fill=[[NSGradient alloc] initWithStartingColor:self.bottomColor endingColor:self.topColor];
    stroke=[[NSGradient alloc] initWithStartingColor:blendedBottom endingColor:blendedTop];
    
    if (!selectedFill) {
        selectedFill=[[NSGradient alloc] initWithStartingColor:[NSColor alternateSelectedControlColor]
                                                   endingColor:[NSColor selectedControlColor]];

    }

    if (!selectedStroke) {
        selectedStroke=[[NSGradient alloc] initWithStartingColor:[[NSColor alternateSelectedControlColor] shadowWithLevel:.4]
                                                   endingColor:[[NSColor selectedControlColor] highlightWithLevel:.5]];
    }
    
    if (!highlightedFill) {
        highlightedFill=[[NSGradient alloc] initWithStartingColor:highlightBottom endingColor:highlightTop];
    }
    
    if (!highlightedStroke) {
        highlightedStroke=[[NSGradient alloc] initWithStartingColor:[highlightBottom shadowWithLevel:.4]
                                                        endingColor:[highlightTop highlightWithLevel:.5]];
    }
}

- (void)setBottomColor:(NSColor *)bottomColor
{
    [_bottomColor release];
    _bottomColor=[bottomColor copy];
    [self updateGradients];
    [self setNeedsDisplay:YES]; 
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius=cornerRadius;
    
    [rect release];
    rect=[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1., 1., self.frame.size.width-2., self.frame.size.height-2.)
                                          xRadius:self.cornerRadius
                                          yRadius:self.cornerRadius] retain];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    
    if ([self isSelected]) {
        if ([self isHighlighted]) {
            [[[NNCollectionItemBox baseHighlightColor] shadowWithLevel:.3] setStroke];
        } else {
            [[[NSColor alternateSelectedControlColor] shadowWithLevel:.3] setStroke];
        }
    } else {
        if ([self isHighlighted]) {
            [[[NNCollectionItemBox baseHighlightColor] shadowWithLevel:.3] setStroke];
        } else {
            [[[NSColor controlShadowColor] shadowWithLevel:.3] setStroke];
        }
    }
    
    [rect setLineWidth:2.];
    [rect stroke];

    if ([self isSelected]) {
        if ([self isHighlighted]) {
            [highlightedFill drawInBezierPath:rect angle:90.];
        } else {
            [selectedFill drawInBezierPath:rect angle:90.];
        }
    } else {
        if ([self isHighlighted]) {
            [highlightedFill drawInBezierPath:rect angle:90.];
        } else {
            [fill drawInBezierPath:rect angle:90.];
        }
    }
    
    CGContextRef ctx=[[NSGraphicsContext currentContext] graphicsPort];
    CGPathRef path=[rect copyQuartzPath];
    CGContextAddPath(ctx, path);
    CGContextReplacePathWithStrokedPath(ctx);
    CGContextClip(ctx);
    
    NSRect frameRect=NSMakeRect(0., 0., self.frame.size.width, self.frame.size.height);
    
    if ([self isSelected]) {
        if ([self isHighlighted]) {
            [highlightedStroke drawInRect:frameRect angle:90.];
        } else {
            [selectedStroke drawInRect:frameRect angle:90.];
        }
    } else {
        if ([self isHighlighted]) {
            [highlightedStroke drawInRect:frameRect angle:90.];
        } else {
            [stroke drawInRect:frameRect angle:90.];
        }
    }
    
    CGPathRelease(path);
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    

    [rect release];
    rect=[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1., 1., newSize.width-2., newSize.height-2.)
                                          xRadius:self.cornerRadius
                                          yRadius:self.cornerRadius] retain];
    [self setNeedsDisplay:YES]; 

}

- (void)dealloc
{
    self.topColor=nil;
    self.bottomColor=nil;
    [rect release];
    [fill release];
    [stroke release];
    [selectedFill release];
    [selectedStroke release];
    [highlightedStroke release];
    [highlightedFill release];
    
    [super dealloc];
}

@end
