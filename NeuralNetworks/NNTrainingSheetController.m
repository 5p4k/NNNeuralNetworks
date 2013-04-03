//
//  NNTrainingSheetController.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 25/05/12.
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

#import "NNTrainingSheetController.h"
#import "NNGlyph.h"
#import "NNGlyphsClass.h"
#import "NNFeedForwardNetwork.h"

@interface NNTrainingSheetController ()
- (void)trainInternal;
@end

@implementation NNTrainingSheetController
@synthesize progress=_progress,glyphsClasses=_glyphsClasses,maximizeSelectivity=_maximizeSelectivity,reuseTimes=_reuseTimes,useReuse=_useReuse;

- (void)awakeFromNib
{
    self.useReuse=YES;
    self.reuseTimes=60;
    self.maximizeSelectivity=YES;
}

- (void)startTrainingProcess:(id)sender
{

    [sender setEnabled:NO];
    // change text
    [[self.window.contentView viewWithTag:1] setStringValue:@"Training networks..."];
    for (NSUInteger i=2; i<=6; ++i)
        [[self.window.contentView viewWithTag:i] setEnabled:NO];

    training=YES;
    [self performSelectorInBackground:@selector(trainInternal) withObject:nil];
}

- (void)cancelTraining:(id)sender
{
    [sender setEnabled:NO];
    if (training) {
        cancelFlag=YES;
    } else {
        [NSApp stopModal];
    }
}


- (void)trainInternal
{
    NSMutableArray *randomizedGlyphs=[[NSMutableArray alloc] initWithCapacity:100];
    NSMutableArray *glyphsPointers=[[NSMutableArray alloc] initWithCapacity:100];
    NSMutableSet *badExamples=[[NSMutableSet alloc] initWithCapacity:100];
    NSMutableArray *networkStatus=[[NSMutableArray alloc] initWithCapacity:100];
    NSSize sz=NSMakeSize(M_NETWORK_INPUT_X, M_NETWORK_INPUT_Y);
    
    CGFloat progressStep=1./(double)self.glyphsClasses.count;
    
    for (NNGlyphsClass *gc in self.glyphsClasses)
        [gc ensureGlyphsHaveTheSameSize];
    
    // perform training.
    for (NSUInteger i=0; i<self.glyphsClasses.count; ++i) {
        
        NNGlyphsClass *gc=[self.glyphsClasses objectAtIndex:i];
                
        // reset everything
        [networkStatus removeAllObjects];
        [gc.network resetNetwork];
        [gc.network setEpsilon:0.0005];
        [gc clearErrors];
                
        // create a randomized copy of the glyphs
        [randomizedGlyphs removeAllObjects];
        // repeat n times if necessary
        [randomizedGlyphs addObjectsFromArray:gc.glyphs];
        if (self.useReuse && gc.glyphs.count<self.reuseTimes) {
            NSUInteger times=(NSUInteger)(self.reuseTimes/gc.glyphs.count);
            NSUInteger rem=self.reuseTimes%gc.glyphs.count;
            for (NSUInteger i=1; i<times; ++i)
                [randomizedGlyphs addObjectsFromArray:gc.glyphs];
            for (NSUInteger i=0; i<rem; ++i)
                [randomizedGlyphs addObject:[gc.glyphs objectAtIndex:i]];            
        }
        
        if (randomizedGlyphs.count>self.reuseTimes && self.useReuse)
            [randomizedGlyphs removeObjectsInRange:NSMakeRange(self.reuseTimes, randomizedGlyphs.count-self.reuseTimes)];
        
        NSUInteger count=randomizedGlyphs.count;
        
        // create an array of pointers
        [glyphsPointers removeAllObjects];
        for (NSUInteger i=0; i<count; ++i) {
            NNGlyph *g=[randomizedGlyphs objectAtIndex:i];
            
            if (!g.inputVector) [g computeInputVectorForSize:sz];
            [glyphsPointers addObject:[NSValue valueWithPointer:g.inputVector]];
        }
        
        // save errors and network status
        [gc storeErrors:NSMakePoint([gc errorOnExamplesArray:glyphsPointers],
                                    [gc selectivityErrorOnClassesArray:self.glyphsClasses])];
        [networkStatus addObject:[gc.network dataWithNetworkStatus]];
        
        [badExamples removeAllObjects];
        
        // train this
        for (NSUInteger j=0; j<count; ++j) {
            
            NSUInteger rnd;
            
            // check if you have to give a "bad example"
            if (j%2==0) {
                
                // pick another class at random
                rnd=arc4random()%(self.glyphsClasses.count-1);
                if (rnd>=i) rnd++;
                
                NNGlyphsClass *rndClass=[self.glyphsClasses objectAtIndex:rnd];
                
                rnd=arc4random()%rndClass.glyphs.count;
                
                NNGlyph *badExample=[rndClass.glyphs objectAtIndex:rnd];
                [badExamples addObject:badExample];
                if (!badExample.inputVector) [badExample computeInputVectorForSize:sz];
                
                // give a "bad example"
                [gc.network trainWithExample:badExample.inputVector
                              expectedResult:NO
                             epsilonFunction:nil];
                
                // error things...
                [gc storeErrors:NSMakePoint([gc errorOnExamplesArray:glyphsPointers],
                                            [gc selectivityErrorOnClassesArray:self.glyphsClasses])];
                [networkStatus addObject:[gc.network dataWithNetworkStatus]];

                
            }
            
            // give a good example
            rnd=arc4random()%randomizedGlyphs.count;
            
            [gc.network trainWithExample:[(NNGlyph *)[randomizedGlyphs objectAtIndex:rnd] inputVector]
                          expectedResult:YES
                         epsilonFunction:nil];
            
            // remove the example
            [randomizedGlyphs removeObjectAtIndex:rnd];
            
            // error things...
            [gc storeErrors:NSMakePoint([gc errorOnExamplesArray:glyphsPointers],
                                        [gc selectivityErrorOnClassesArray:self.glyphsClasses])];
            [networkStatus addObject:[gc.network dataWithNetworkStatus]];

            
            [self setProgress:progressStep*(((double)i)+((double)j)/(double)count)];
            
            if (cancelFlag) {
                [glyphsPointers release];
                [randomizedGlyphs release];
                [networkStatus release];
                [badExamples release];

                [NSApp performSelectorOnMainThread:@selector(stopModal) withObject:nil waitUntilDone:NO];
                return;
            }
            
        }
        
        // now reset the network to its best configuration.
        
        // find the minimum for the learning process
        NSUInteger min=0; CGFloat minValue=INFINITY;
        for (NSUInteger k=0; k<gc.errors.count; ++k) {
            CGFloat err=[[gc.errors objectAtIndex:k] pointValue].x;
            if (err<minValue) {
                min=k;
                minValue=err;
            }
        }
        // find the maximum selectivity
        if (self.maximizeSelectivity) {
            minValue=INFINITY;
            for (NSUInteger k=min; k<gc.errors.count; ++k) {
                CGFloat err=[[gc.errors objectAtIndex:k] pointValue].y*[[gc.errors objectAtIndex:k] pointValue].x;
                if (err<minValue) {
                    min=k;
                    minValue=err;
                }
            }
        }
        
        // that is the best result
        [gc.network loadNetworkStatusFromData:[networkStatus objectAtIndex:min]];
        
        [gc computeAverageOnGlyphs];
        [gc computeAverageOnOtherGlyphs:badExamples];
        
        [self setProgress:progressStep*((double)i+1)];
        
        if (cancelFlag) {
            [glyphsPointers release];
            [randomizedGlyphs release];
            [networkStatus release];
            [badExamples release];

            [NSApp performSelectorOnMainThread:@selector(stopModal) withObject:nil waitUntilDone:NO];
            return;
        }
        
    }
    
    [glyphsPointers release];
    [randomizedGlyphs release];
    [networkStatus release];
    [badExamples release];
    
    [NSApp performSelectorOnMainThread:@selector(stopModal) withObject:nil waitUntilDone:NO];
}

@end
