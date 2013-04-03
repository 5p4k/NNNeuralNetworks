//
//  NNFeedForwardNetwork.m
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

#import "NNFeedForwardNetwork.h"

@interface NNFeedForwardNetwork ()
- (CGFloat)errorOnExample:(const float *)input expectedResult:(BOOL)xi;
@end

@implementation NNFeedForwardNetwork
@synthesize inputSize=_inputSize,transferFunction=_transferFunction,examplesGiven=_examplesGiven,neuronsCount=_neuronsCount,sigmoidScaleFactor=_sigmoidScaleFactor,epsilon=_epsilon;

- (id)initWithInputSize:(NSUInteger)n neurons:(NSUInteger)h
{
    if (n<=1 || h<=1) return nil;
    
    if ((self=[super init])) {
        
        _inputSize=n;
        _neuronsCount=h;
        _transferFunction=NNSigmoidal;
        _sigmoidScaleFactor=1.;
        _epsilon=.001;
        
        matrix=malloc(sizeof(float)*(n+1)*h);
        pMatrix=malloc(sizeof(float)*(h+1));
        extInput=malloc(sizeof(float)*(n+1));
        pExtInput=malloc(sizeof(float)*(h+1));
        extInput[n]=1.;
        pExtInput[h]=1.;
        
        [self resetNetwork];
        
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self=[super init])) {
        _transferFunction=(NNTransferFunction)[aDecoder decodeIntegerForKey:@"NNFeedForwardNetwork->_transferFunction"];
        _epsilon=[aDecoder decodeDoubleForKey:@"NNFeedForwardNetwork->_epsilon"];
        _sigmoidScaleFactor=[aDecoder decodeDoubleForKey:@"NNFeedForwardNetwork->_sigmoidScaleFactor"];
        _examplesGiven=[aDecoder decodeIntegerForKey:@"NNFeedForwardNetwork->_examplesGiven"];
        _neuronsCount=[aDecoder decodeIntegerForKey:@"NNFeedForwardNetwork->_neuronsCount"];
        _inputSize=[aDecoder decodeIntegerForKey:@"NNFeedForwardNetwork->_inputSize"];
        
        matrix=malloc(sizeof(float)*(self.inputSize+1)*self.neuronsCount);
        pMatrix=malloc(sizeof(float)*(self.neuronsCount+1));
        extInput=malloc(sizeof(float)*(self.inputSize+1));
        pExtInput=malloc(sizeof(float)*(self.neuronsCount+1));
        extInput[self.inputSize]=1.;
        pExtInput[self.neuronsCount]=1.;
        
        NSUInteger len;
        const uint8_t *temp=[aDecoder decodeBytesForKey:@"NNFeedForwardNetwork->pMatrix" returnedLength:&len];
        if (len!=sizeof(float)*(self.neuronsCount+1)) {
            NSLog(@"Error while unarchiving: declared network parameters do not match data length.");
        } else {
            memcpy(pMatrix, temp, len);
        }
        
        temp=[aDecoder decodeBytesForKey:@"NNFeedForwardNetwork->matrix" returnedLength:&len];
        if (len!=sizeof(float)*(self.inputSize+1)*self.neuronsCount) {
            NSLog(@"Error while unarchiving: declared network parameters do not match data length.");
        } else {
            memcpy(matrix, temp, len);
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeBytes:(const uint8_t *)matrix length:sizeof(float)*(self.inputSize+1)*self.neuronsCount forKey:@"NNFeedForwardNetwork->matrix"];
    [aCoder encodeBytes:(const uint8_t *)pMatrix length:sizeof(float)*(self.neuronsCount+1) forKey:@"NNFeedForwardNetwork->pMatrix"];

    [aCoder encodeInteger:_inputSize forKey:@"NNFeedForwardNetwork->_inputSize"];
    [aCoder encodeInteger:_neuronsCount forKey:@"NNFeedForwardNetwork->_neuronsCount"];
    [aCoder encodeInteger:_examplesGiven forKey:@"NNFeedForwardNetwork->_examplesGiven"];
    [aCoder encodeDouble:_sigmoidScaleFactor forKey:@"NNFeedForwardNetwork->_sigmoidScaleFactor"];
    [aCoder encodeDouble:_epsilon forKey:@"NNFeedForwardNetwork->_epsilon"];
    [aCoder encodeInteger:_transferFunction forKey:@"NNFeedForwardNetwork->_transferFunction"];
}

- (CGFloat)resultForInput:(const float *)input
{
    memcpy(extInput, input, sizeof(float)*self.inputSize);
    
    for (NSUInteger i=0; i<self.neuronsCount; ++i)
        pExtInput[i]=cblas_sdot((int)(self.inputSize+1), extInput, 1, &matrix[(self.inputSize+1)*i], 1);
    
    CGFloat result=cblas_sdot((int)(self.neuronsCount+1), pExtInput, 1, pMatrix, 1);
    
    if (self.transferFunction==NNLinear)
        return result;
    return tanhf(self.sigmoidScaleFactor*result);
    
}

- (id)copyWithZone:(NSZone *)zone
{
    NNFeedForwardNetwork *ffn=[[NNFeedForwardNetwork alloc] initWithInputSize:self.inputSize
                                                                      neurons:self.neuronsCount];
    
    ffn->_examplesGiven=self.examplesGiven;
    ffn.transferFunction=self.transferFunction;
    ffn.sigmoidScaleFactor=self.sigmoidScaleFactor;
    ffn.epsilon=self.epsilon;
    
    memcpy(ffn->matrix, matrix, sizeof(float)*(self.inputSize+1)*self.neuronsCount);
    memcpy(ffn->pMatrix, pMatrix, sizeof(float)*(self.neuronsCount+1));
    
    return ffn;
}

- (NSData *)dataWithNetworkStatus
{
    NSMutableData *output=[NSMutableData dataWithBytes:matrix length:sizeof(float)*(self.inputSize+1)*self.neuronsCount];
    
    [output appendBytes:pMatrix length:sizeof(float)*(self.neuronsCount+1)];
    [output appendBytes:&_examplesGiven length:sizeof(NSUInteger)];
    
    return output;
}

- (void)loadNetworkStatusFromData:(NSData *)data
{
    [self willChangeValueForKey:@"examplesGiven"];
    NSUInteger pos=0;
    NSUInteger len=sizeof(float)*(self.inputSize+1)*self.neuronsCount;
    [data getBytes:matrix length:len];
    pos+=len;
    len=sizeof(float)*(self.neuronsCount+1);
    [data getBytes:pMatrix range:NSMakeRange(pos,len)];
    pos+=len;
    len=sizeof(NSUInteger);
    [data getBytes:&_examplesGiven range:NSMakeRange(pos, len)];
    [self didChangeValueForKey:@"examplesGiven"];
}

- (void)trainWithExample:(const float *)input expectedResult:(BOOL)xi epsilonFunction:(CGFloat(^)(NNFeedForwardNetwork *))f
{
    CGFloat y=[self resultForInput:input];
    CGFloat x=(xi ? 1. : -1.);
    CGFloat epsilon=(f ? f(self) : self.epsilon);
    CGFloat coefficient=x-y;
    
    // this is not thread safe!!! Should be fixed
    // extInput contains input, extended with "1" at the end
    
    // update perceptron
    cblas_saxpy((int)(self.neuronsCount+1), epsilon*coefficient, pExtInput, 1, pMatrix, 1);
    
    // update hidden layer
    for (NSUInteger i=0; i<self.neuronsCount; ++i) {
        float *weights=&matrix[i*(self.inputSize+1)];
        cblas_saxpy((int)(self.inputSize+1), coefficient*epsilon*pMatrix[i], extInput, 1, weights, 1);
    }
    
    [self willChangeValueForKey:@"examplesGiven"];
    ++_examplesGiven;
    [self didChangeValueForKey:@"examplesGiven"];
}

- (void)trainWithExample:(const float *)input expectedResult:(BOOL)xi
{
    [self trainWithExample:input expectedResult:xi epsilonFunction:nil];
}

- (CGFloat)errorOnExample:(const float *)input expectedResult:(BOOL)xi
{
    CGFloat y=[self resultForInput:input];
    CGFloat x=(xi ? 1. : -1.);
    
    return (y*y+x*x)-x*y;
}

- (CGFloat)errorOnExamplesSet:(NSSet *)set
{
    if (set.count==0) return NAN;
    CGFloat avg=0.;
    for (NSValue *input in set)
        avg+=[self errorOnExample:[input pointerValue] expectedResult:YES];
    
    return .5*avg;
}

- (CGFloat)errorOnExamplesArray:(NSArray *)arr
{
    if (arr.count==0) return NAN;
    CGFloat avg=0.;
    for (NSValue *input in arr)
        avg+=[self errorOnExample:[input pointerValue] expectedResult:YES];
    
    return .5*avg;
}

- (void)resetNetwork
{
    _examplesGiven=0;
    for (NSUInteger i=0; i<(self.inputSize+1)*self.neuronsCount; ++i)
        matrix[i]=.05*((float)(-0x7FFFFF+(NSInteger)(arc4random()%0xFFFFFF)))/(float)(0x7FFFFF);
    for (NSUInteger i=0; i<=self.neuronsCount+1; ++i)
        pMatrix[i]=.05*((float)(-0x7FFFFF+(NSInteger)(arc4random()%0xFFFFFF)))/(float)(0x7FFFFF);
    for (NSUInteger i=0; i<self.neuronsCount; ++i)
        for (NSUInteger j=0; j<self.inputSize; ++j)
            if (fabs(matrix[i*(self.inputSize+1)+self.inputSize])<fabs(matrix[i*(self.inputSize+1)+j]))
                matrix[i*(self.inputSize+1)+self.inputSize]=matrix[i*(self.inputSize+1)+j];
    
    for (NSUInteger i=0; i<self.neuronsCount; ++i)
        if (fabs(pMatrix[self.neuronsCount])<fabs(pMatrix[i]))
            pMatrix[self.neuronsCount]=pMatrix[i];
    
}

- (void)dealloc
{
    free(matrix);
    free(extInput);
    free(pMatrix);
    free(pExtInput);
    
    [super dealloc];
}
@end
