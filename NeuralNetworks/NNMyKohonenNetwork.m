//
//  NNMyKohonenNetwork.m
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

#import "NNMyKohonenNetwork.h"

@implementation NNMyKohonenNetwork
@synthesize imageSize=_imageSize,epsilon=_epsilon,epsilonDecreaseFactor=_epsilonDecreaseFactor,sigma=_sigma,sigmaDecreaseFactor=_sigmaDecreaseFactor;

- (id)init
{
    if ((self=[super initWithInputSize:M_NETWORK_INPUT_X*M_NETWORK_INPUT_Y neurons:M_KN_GLYPH_CLUSTERING andDelegate:self])) {
        _imageSize=CGSizeMake(M_NETWORK_INPUT_X, M_NETWORK_INPUT_Y);
        tempForNorm=malloc(sizeof(float)*(self.inputSize+1));
        _sigma=1.;
        _epsilon=.2;
        _epsilonDecreaseFactor=180.;
        _sigmaDecreaseFactor=180.;
    }
    
    return self;

}
- (id)initWithImageSize:(NSSize)sz neurons:(NSUInteger)h
{
    if ((self=[super initWithInputSize:(NSUInteger)(sz.width*sz.height) neurons:h andDelegate:self])) {
        _imageSize=sz;
        tempForNorm=malloc(sizeof(float)*(self.inputSize+1));
        _sigma=1.;
        _epsilon=.2;
        _epsilonDecreaseFactor=180.;
        _sigmaDecreaseFactor=180.;
    }
    
    return self;
}

- (void)dealloc
{
    free(tempForNorm);
    
    [super dealloc];
}

- (void)trainWinnerWithImage:(NSImage *)input
{
    NSBitmapImageRep *rep=[input imageRepWithNNInputOfSize:self.imageSize clamp:YES];
    
    [super trainWinnerWithExample:(const float *)rep.bitmapData];
}

- (NSUInteger)winnerForImage:(NSImage *)input
{
    NSBitmapImageRep *rep=[input imageRepWithNNInputOfSize:self.imageSize clamp:YES];
    
    NSUInteger winner=[super winnerForInput:(const float *)rep.bitmapData];

    return winner;
}

- (void)trainWinnerWithImageRep:(NSImageRep *)input
{
    NSBitmapImageRep *rep=[input imageRepWithNNInputOfSize:self.imageSize clamp:YES];
    
    [super trainWinnerWithExample:(const float *)rep.bitmapData];
    
}

- (NSUInteger)winnerForImageRep:(NSImageRep *)input
{
    NSBitmapImageRep *rep=[input imageRepWithNNInputOfSize:self.imageSize clamp:YES];
    
    NSUInteger winner=[super winnerForInput:(const float *)rep.bitmapData];
    
    return winner;
}

- (CGFloat)kohonenNetworkEpsilonForTraining:(NNKohonenNetwork *)kn
{
    if (self.sigmaDecreaseFactor==0.) return self.epsilon;
    
    return self.epsilon*exp(-4.*((double)kn.examplesGiven)/self.epsilonDecreaseFactor);
}

- (CGFloat)kohonenNetwork:(NNKohonenNetwork *)kn distanceBetweenInput:(const float *)input andWeights:(const float *)weights ofSize:(NSUInteger)size
{
    memcpy(tempForNorm, input, size*sizeof(float));
    cblas_saxpy((int)size, -1., weights, 1, tempForNorm, 1);
    
    return cblas_snrm2((int)size, tempForNorm, 1);
}

- (CGFloat)kohonenNetwork:(NNKohonenNetwork *)kn trainingRuleForNeuron:(NSUInteger)neuron withWinner:(NSUInteger)winner
{
    CGFloat sigma=self.sigma;
    if (self.sigmaDecreaseFactor!=0.)
        sigma*=exp(-4.*((double)kn.examplesGiven)/self.sigmaDecreaseFactor);
    sigma*=sigma;

    CGFloat x=((CGFloat)neuron)-(CGFloat)winner;
    x*=x;
    
    return exp(-.5*x/sigma);
}

@end
