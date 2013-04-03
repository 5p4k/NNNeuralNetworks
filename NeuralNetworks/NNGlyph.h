//
//  NNConnectedComponent.h
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 09/05/12.
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

#import <Foundation/Foundation.h>

@interface NNGlyph : NSObject <NSCoding> {
    NSInteger baryX;
    NSInteger baryY;
    NSUInteger *yNorms;
    float *_inputVector;
}
@property (readonly) NSRect rect;
@property (readonly) NSBitmapImageRep *imageRep;
@property (readonly) NSImage *image;
@property (readonly) NSUInteger size;
@property (readonly) NSPoint barycenter;
@property (retain) NSValue *line;
@property (readonly) const float *inputVector;

- (void)expandToIncludeX:(NSUInteger)x y:(NSUInteger)y;
- (void)setupImage;
- (void)addPointX:(NSUInteger)x y:(NSUInteger)y;
- (void)removePointX:(NSUInteger)x y:(NSUInteger)y;
- (BOOL)valueOfPointX:(NSUInteger)x y:(NSUInteger)y;
- (BOOL)sizeGreaterThanFractionOfRect:(CGFloat)fraction;
+ (NNGlyph *)connectedComponentByMerging:(NNGlyph *)a with:(NNGlyph *)b;
- (NSArray *)splitAtX:(NSUInteger)x;
- (NSInteger)findHorizontalMinimum:(NSUInteger *)x inRange:(NSRange)rg greaterThan:(NSUInteger)min;
- (NSComparisonResult)compare:(NNGlyph *)c;
- (void)expandImageToSize:(NSSize)size;
- (void)computeInputVectorForSize:(NSSize)sz;
- (void)discardInputVector;
@end
