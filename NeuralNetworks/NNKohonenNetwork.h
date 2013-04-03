//
//  NNKohonenNetwork.h
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

#import <Foundation/Foundation.h>

@class NNKohonenNetwork;

@protocol NNKohonenNetworkDelegate <NSObject>
@required
- (CGFloat)kohonenNetwork:(NNKohonenNetwork * )kn distanceBetweenInput:(const float *)input andWeights:(const float *)weights ofSize:(NSUInteger)size;
- (CGFloat)kohonenNetwork:(NNKohonenNetwork * )kn trainingRuleForNeuron:(NSUInteger)neuron withWinner:(NSUInteger)winner;
- (CGFloat)kohonenNetworkEpsilonForTraining:(NNKohonenNetwork *)kn;
@optional
- (void)kohonenNetwork:(NNKohonenNetwork *)kn trainedWinner:(NSUInteger)winner withExample:(const float *)input;
@end

@interface NNKohonenNetwork : NSObject {
    float *matrix;
    float *extInput;
    float *tempDelta;
}
@property (assign) BOOL normalizeInput;
@property (readonly) NSUInteger inputSize;
@property (readonly) NSUInteger neuronsCount;
@property (readonly) NSUInteger examplesGiven;
@property (assign) id <NNKohonenNetworkDelegate> delegate;

- (id)initWithInputSize:(NSUInteger)n neurons:(NSUInteger)h andDelegate:(id <NNKohonenNetworkDelegate>)delegate;
- (void)resetNetwork;
- (NSUInteger)winnerForInput:(const float *)input;
- (void)trainWinnerWithExample:(const float *)input;

@end
