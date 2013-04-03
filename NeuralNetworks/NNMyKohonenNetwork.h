//
//  NNMyKohonenNetwork.h
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 12/05/12.
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

#import "NNKohonenNetwork.h"

@interface NNMyKohonenNetwork : NNKohonenNetwork <NNKohonenNetworkDelegate> {
    float *tempForNorm;
}
@property (readonly) NSSize imageSize;
@property (assign) CGFloat epsilon;
@property (assign) CGFloat epsilonDecreaseFactor;
@property (assign) CGFloat sigmaDecreaseFactor;
@property (assign) CGFloat sigma;

- (id)init;
- (id)initWithImageSize:(NSSize)sz neurons:(NSUInteger)h;
- (NSUInteger)winnerForImage:(NSImage *)input;
- (void)trainWinnerWithImage:(NSImage *)input;
- (NSUInteger)winnerForImageRep:(NSImageRep *)input;
- (void)trainWinnerWithImageRep:(NSImageRep *)input;

@end
