//
//  NNFeedForwardNetwork.h
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 22/05/12.
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

typedef enum {
    NNSigmoidal,
    NNLinear
} NNTransferFunction;

@interface NNFeedForwardNetwork : NSObject <NSCoding,NSCopying> {
    float *matrix;
    float *pMatrix;
    float *extInput;
    float *pExtInput;
}
@property (readonly) NSUInteger inputSize;
@property (readonly) NSUInteger neuronsCount;
@property (readonly) NSUInteger examplesGiven;
@property (assign) NNTransferFunction transferFunction;
@property (assign) CGFloat sigmoidScaleFactor;
@property (assign) CGFloat epsilon;

- (id)initWithInputSize:(NSUInteger)n neurons:(NSUInteger)h;
- (void)resetNetwork;
- (CGFloat)resultForInput:(const float *)input;
- (void)trainWithExample:(const float *)input expectedResult:(BOOL)xi;
- (void)trainWithExample:(const float *)input expectedResult:(BOOL)xi epsilonFunction:(CGFloat(^)(NNFeedForwardNetwork *))f;
- (CGFloat)errorOnExamplesArray:(NSArray *)arr;
- (CGFloat)errorOnExamplesSet:(NSSet *)set;
- (NSData *)dataWithNetworkStatus;
- (void)loadNetworkStatusFromData:(NSData *)data;
@end
