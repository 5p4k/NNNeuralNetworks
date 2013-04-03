//
//  NNKohonenNetwork.m
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

@implementation NNKohonenNetwork
@synthesize inputSize=_inputSize, neuronsCount=_neuronsCount, delegate=_delegate, examplesGiven=_examplesGiven,normalizeInput=_normalizeInput;

- (id)initWithInputSize:(NSUInteger)n neurons:(NSUInteger)h andDelegate:(id<NNKohonenNetworkDelegate>)delegate
{
    if (n<=1 || h<=1 || delegate==nil) return nil;
    
    if ((self=[super init])) {
        
        _inputSize=n;
        _neuronsCount=h;
        _delegate=delegate;
        _normalizeInput=YES;
        
        matrix=malloc(sizeof(float)*(n+1)*h);
        extInput=malloc(sizeof(float)*(n+1));
        tempDelta=malloc(sizeof(float)*(n+1));
        extInput[n]=1.;
        
        [self resetNetwork];
        
    }
    
    return self;
}

- (void)dealloc
{
    free(matrix);
    free(extInput);
    free(tempDelta);
    
    [super dealloc];
}

- (NSUInteger)winnerForInput:(const float *)input
{
    memcpy(extInput, input, sizeof(float)*self.inputSize);
    
    if (self.normalizeInput)
        cblas_sscal((int)(self.inputSize+1), 1./cblas_snrm2((int)(self.inputSize+1), extInput, 1), extInput, 1);
    
    NSUInteger winner=0; CGFloat distance=0.;
    for (NSUInteger i=0; i<self.neuronsCount; ++i) {
        if (i==0) {
            winner=0;
            distance=[self.delegate kohonenNetwork:self
                              distanceBetweenInput:extInput
                                        andWeights:matrix
                                            ofSize:self.inputSize+1];
;
        } else {
            CGFloat thisDistance=[self.delegate kohonenNetwork:self
                                          distanceBetweenInput:extInput
                                                    andWeights:&matrix[i*(self.inputSize+1)]
                                                        ofSize:self.inputSize+1];
            if (thisDistance<distance) {
                winner=i;
                distance=thisDistance;
            }
        }
    }
    
    return winner;
}

- (void)trainWinnerWithExample:(const float *)input
{
    NSUInteger winner=[self winnerForInput:input];
    CGFloat epsilon=[self.delegate kohonenNetworkEpsilonForTraining:self];

    // update weights
    for (NSUInteger i=0; i<self.neuronsCount; ++i) {
        
        float *weights=&matrix[i*(self.inputSize+1)];
        
        // this is not thread safe!!! This should be fixed.
        // extInput contains input, extended with "1" at the end
        
        CGFloat coefficient=[self.delegate kohonenNetwork:self 
                                    trainingRuleForNeuron:i
                                               withWinner:winner];
        
        memcpy(tempDelta, extInput, sizeof(float)*(self.inputSize+1));
        cblas_saxpy((int)(self.inputSize+1), -1., weights, 1, tempDelta, 1);
        cblas_saxpy((int)(self.inputSize+1), coefficient*epsilon, tempDelta, 1, weights, 1);
        
    }
    
    ++_examplesGiven;
}

- (void)resetNetwork
{
    _examplesGiven=0;
    for (NSUInteger i=0; i<(self.inputSize+1)*self.neuronsCount; ++i)
        matrix[i]=.6*((float)(-0x7FFFFF+(NSInteger)(arc4random()%0xFFFFFF)))/(float)(0x7FFFFF);
    if (self.normalizeInput) {
        for (NSUInteger h=0; h<self.neuronsCount; ++h) {
            float *weights=&matrix[h*(self.inputSize+1)];
            cblas_sscal((int)(self.inputSize+1), 1./cblas_snrm2((int)(self.inputSize+1), weights, 1), weights, 1);
        }
    }
}

@end
