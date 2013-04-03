//
//  NNGlyphCollectionViewItem.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 20/05/12.
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

#import "NNGlyphCollectionViewItem.h"
#import "NNGlyphView.h"

@implementation NNGlyphCollectionViewItem
@synthesize selected=_selected;

- (BOOL)isSelected
{
    if (self.view && [self.view isKindOfClass:[NNGlyphView class]]) {
        return [(NNGlyphView *)self.view isSelected];
    } else {
        return NO;
    }
}

- (void)setSelected:(BOOL)selected
{
    if (self.view && [self.view isKindOfClass:[NNGlyphView class]]) {
        [(NNGlyphView *)self.view setSelected:selected];
    }
}

@end
