//
//  NNHeader.h
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

#import <Cocoa/Cocoa.h>

@class NNCollectionItemBox;

@protocol NNHeaderDraggingDelegate <NSObject>
@required
- (NSString *)headerAllowedDraggingType:(NNCollectionItemBox *)hdr;
- (void)header:(NNCollectionItemBox *)hdr receivedData:(NSData *)data;
@end

@interface NNCollectionItemBox : NSView {
    NSBezierPath *rect;
    NSGradient *fill;
    NSGradient *stroke;
    NSGradient *highlightedFill;
    NSGradient *highlightedStroke;
    NSGradient *selectedFill;
    NSGradient *selectedStroke;
}
@property (assign) id draggingPasteboardToSkip;
@property (assign) IBOutlet id <NNHeaderDraggingDelegate> delegate;
@property (assign,getter=isSelected) BOOL selected;
@property (assign,getter=isHighlighted) BOOL highlighted;
@property (nonatomic, copy) NSColor *topColor;
@property (nonatomic, copy) NSColor *bottomColor;
@property (nonatomic, assign) CGFloat cornerRadius;
@end
