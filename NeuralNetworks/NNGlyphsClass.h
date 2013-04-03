//
//  NNGlyphsClass.h
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 13/05/12.
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

@class NNGlyph;
@class NNFeedForwardNetwork;

@interface NNGlyphsClass : NSObject <NSCoding,NSCopying> {
    NSMutableArray *_errors;
}
@property (copy) NSString *label;
@property (readonly) NSMutableArray *glyphs;
@property (readonly) NSUInteger count;
@property (readonly) NSArray *errors;
@property (readonly) NNFeedForwardNetwork *network;
@property (readonly) NNGlyph *aGlyph;
@property (readonly) CGFloat averageOnGlyphs;
@property (readonly) CGFloat averageOnOtherGlyphs;
@property (readonly) NSSize glyphsCommonSize;

- (CGFloat)selectivityErrorOnClassesSet:(NSSet *)classes;
- (CGFloat)selectivityErrorOnClassesArray:(NSArray *)classes;
- (CGFloat)errorOnExamplesSet:(NSSet *)set;
- (CGFloat)errorOnExamplesArray:(NSArray *)arr;
- (void)clearErrors;
- (void)storeErrors:(NSPoint)err;
- (void)computeAverageOnGlyphs;
- (void)computeAverageOnOtherGlyphs:(NSSet *)otherGlyphs;
- (void)ensureGlyphsHaveTheSameSize;

- (NSString *)description;
@end
