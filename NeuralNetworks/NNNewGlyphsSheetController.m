//
//  NNNewGlyphsSheetController.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 11/05/12.
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

#import "NNNewGlyphsSheetController.h"
#import "NNMatrix.h"
#import "NNGlyphsClassView.h"
#import "NNGlyph.h"
#import "NNGlyphsClass.h"
#import "NNCollectionItemBox.h"
#import "NNMyKohonenNetwork.h"
#import "NNFeedForwardNetwork.h"

@interface NNNewGlyphsSheetController ()
- (void)setImage:(NSImage *)image;
- (void)recomputeLinesInternal;
- (void)mainProcessInternal;
- (void)neuralNetworkProcessInternal;
- (void)markLabelAtIndex:(NSNumber *)index;
- (void)resizeWindow;
@end

@implementation NNNewGlyphsSheetController
@synthesize linesThresholdSlider=_linesThresholdSlider,
            progressIndicator=_progressIndicator,
            spinningIndicator=_spinningIndicator,
            linesDetectionThreshold=_linesDetectionThreshold,
            imageView=_imageView,
            imageMatrix=_imageMatrix,
            linesDetected=_linesDetected,
            resetLinesButton=_resetLinesButton,
            glyphsFound=_glyphsFound,
            glyphsByLine=_glyphsByLine,
            glyphsCountLabel=_glyphsCountLabel,
            glyphsClasses=_glyphsClasses,
            myKohonenNetwork=_myKohonenNetwork,
            sigmaAndEpsilonDecreaseFactor=_sigmaAndEpsilonDecreaseFactor,
            maximumNumberOfExamples=_maximumNumberOfExamples,
            epsilonSlider=_epsilonSlider,
            sigmaSlider=_sigmaSlider,
            examplesSlider=_examplesSlider,
            decreaseFactorSlider=_decreaseFactorSlider,
            startNetworkButton=_startNetworkButton,
            resetNetworkButton=_resetNetworkButton,
            networkResultView=_networkResultView,
            glyphsClassesView=_glyphsClassesView,
            glyphsClassesController=_glyphsClassesController,
            doneButton=_doneButton,
            scanningMode=_scanningMode,
            outputField=_outputField,
            cancelButton=_cancelButton,sortButton=_sortButton;

#pragma mark - Methods related to window startup and shutdown -


+ (NNNewGlyphsSheetController *)trainerSheetControllerWithImage:(NSImage *)img
{
    NNNewGlyphsSheetController *twc=[[NNNewGlyphsSheetController alloc] initWithWindowNibName:@"NNNewGlyphsSheetController"];
    
    [twc setImage:img];
    
    return [twc autorelease];
}

- (void)awakeFromNib
{
    lock=[[NSLock alloc] init];
    
    [self.window setDefaultButtonCell:self.doneButton.cell];
    
    self.sigmaSlider.maxValue=2.*sqrt((double)M_KN_GLYPH_CLUSTERING);
    
    [self.glyphsClassesView setMinItemSize:NSMakeSize(300., 114.)];    
    [self.glyphsClassesView setMaxItemSize:NSMakeSize(1440., 114.)];
    [self.glyphsClassesView setMaxNumberOfColumns:1];
    [self.glyphsClassesView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    [self.glyphsClassesView registerForDraggedTypes:[NSArray arrayWithObject:@"com.SpakSW.NeuralNetworks.Glyph"]];
    
    
    // initialize some variables
    self.linesDetectionThreshold=0.975;
    self.sigmaAndEpsilonDecreaseFactor=.92;
    self.maximumNumberOfExamples=1.;
    self.myKohonenNetwork.epsilon=.6;
    self.myKohonenNetwork.sigma=.407*self.sigmaSlider.maxValue;
    
    // set image to outlet
    if (pendingImage) {
        [self setImage:pendingImage];
        [pendingImage release];
        pendingImage=nil;
        
        // recompute lines
        [self recomputeLines:nil];
    }
    
    // load weak references to the labels
    for (NSUInteger i=0; i<8; ++i)
        stepsLabels[i]=[self.window.contentView viewWithTag:i+1];
}

- (void)dealloc
{
    [lock release];
    [pendingImage release];
    
    self.imageMatrix=nil;
    self.linesDetected=nil;
    self.glyphsFound=nil;
    self.glyphsByLine=nil;
    
    
    [super dealloc];
}

#pragma mark - Custom property implementation -

- (void)resizeWindow
{
    [self.window setFrame:NSMakeRect(0., 0.,
                                     fmax(950., self.window.frame.size.width),
                                     fmax(550., self.window.frame.size.height))
                  display:YES
                  animate:YES];
}

- (NSImage *)image
{
    return (self.imageView ? self.imageView.image : pendingImage);
}

- (void)setImage:(NSImage *)image
{
    self.imageMatrix=(image ? [[[NNMatrix alloc] initWithImage:image] autorelease] : nil);
    
    if (self.imageView) {
        self.imageView.image=image;
    } else {
        [pendingImage release];
        pendingImage=[image retain];
    }
}

- (CGFloat)sigmaAndEpsilonDecreaseFactor
{
    return _sigmaAndEpsilonDecreaseFactor;
}

- (CGFloat)maximumNumberOfExamples
{
    return _maximumNumberOfExamples;
}

- (void)setSigmaAndEpsilonDecreaseFactor:(CGFloat)sigmaAndEpsilonDecreaseFactor
{
    self.myKohonenNetwork.epsilonDecreaseFactor=self.myKohonenNetwork.sigmaDecreaseFactor=sigmaAndEpsilonDecreaseFactor*self.maximumNumberOfExamples*(double)self.glyphsFound.count;
    _sigmaAndEpsilonDecreaseFactor=sigmaAndEpsilonDecreaseFactor;
}

- (void)setMaximumNumberOfExamples:(CGFloat)maximumNumberOfExamples
{
    self.myKohonenNetwork.epsilonDecreaseFactor=self.myKohonenNetwork.sigmaDecreaseFactor=self.sigmaAndEpsilonDecreaseFactor*maximumNumberOfExamples*(double)self.glyphsFound.count;
    _maximumNumberOfExamples=maximumNumberOfExamples;
}

#pragma mark - Outlets and similar -

- (void)displaySpinningIndicator
{
    [self.spinningIndicator setHidden:NO];
    [self.spinningIndicator startAnimation:self];
}

- (void)hideSpinningIndicator
{
    [self.spinningIndicator stopAnimation:self];
    [self.spinningIndicator setHidden:YES];
}

- (void)startImageScanningProcess:(id)sender
{
    processRunning=YES;
    
    // disable all the controls
    [(NSButton *)sender setEnabled:NO];
    
    [self.linesThresholdSlider setEnabled:NO];
    [self.resetLinesButton setEnabled:NO];
    [(NSTextField *)stepsLabels[0] setTextColor:[NSColor disabledControlTextColor]];
    [(NSTextField *)stepsLabels[1] setTextColor:[NSColor disabledControlTextColor]];
    [(NSTextField *)stepsLabels[2] setTextColor:[NSColor disabledControlTextColor]];
    [stepsLabels[3] setEnabled:NO];
    [stepsLabels[4] setEnabled:NO];
    [(NSTextField *)stepsLabels[5] setTextColor:[NSColor disabledControlTextColor]];
    
    [self performSelectorInBackground:@selector(mainProcessInternal) withObject:nil];


}

- (void)startNeuralNetworkProcess:(id)sender
{
    processRunning=YES;
    
    // disable all the controls
    [(NSButton *)sender setEnabled:NO];

    [self.imageView setHidden:YES];
    [self.networkResultView setHidden:NO];
    [self.doneButton setEnabled:NO];
    
    [self.epsilonSlider setEnabled:NO];
    [self.resetNetworkButton setEnabled:NO];
    [self.sigmaSlider setEnabled:NO];
    [self.examplesSlider setEnabled:NO];
    [self.decreaseFactorSlider setEnabled:NO];
    [self.sortButton setEnabled:NO];
    [(NSTextField *)stepsLabels[6] setTextColor:[NSColor disabledControlTextColor]];
    [(NSTextField *)stepsLabels[7] setTextColor:[NSColor disabledControlTextColor]];
    [self performSelectorInBackground:@selector(neuralNetworkProcessInternal) withObject:nil];

}

- (void)imageViewWantsToDrawExtraContent:(NNImageView *)nniv
{
    if (self.glyphsFound) {
        
        // setup colors
        [[NSColor colorWithCalibratedRed:.95 green:0. blue:0. alpha:.3] setFill];
        
        [lock lock];
        NSArray *arr=[self.glyphsFound allObjects];
        [lock unlock];
        for (NNGlyph *g in arr)
            [NSBezierPath fillRect:g.rect];
        
    } else if (self.linesDetected) {
        
        // setup colors
        [[NSColor colorWithCalibratedRed:.95 green:0. blue:0. alpha:.3] setFill];
        [[NSColor colorWithCalibratedRed:.9 green:0. blue:0. alpha:.9] setStroke];
        
        for (NSValue *line in self.linesDetected) {
            
            // extract range and rect
            NSRange rg=[line rangeValue];
            NSRect rect=NSMakeRect(0., (CGFloat)rg.location, self.image.size.width, (CGFloat)rg.length);
            
            // draw
            [NSBezierPath fillRect:rect];
            [NSBezierPath strokeRect:rect];
        }
        
    }
}

- (void)recomputeLinesInternal
{
    if (!self.image) return;
    
    if (![self.imageMatrix hasNormOfRows]) [self.imageMatrix computeNormOfRows];
    self.linesDetected=[self.imageMatrix extractRowsWithThreshold:self.linesDetectionThreshold
                                                            delta:.01
                                                        minLength:(NSUInteger)(self.image.size.height/125.)];
    
    [self.imageView setNeedsDisplay:YES];
    [self hideSpinningIndicator];
}

- (void)cancelAndClose:(id)sender
{
    [sender setEnabled:NO];
    if (processRunning) {
        [self displaySpinningIndicator];
        cancelFlag=YES;
    } else {
        self.glyphsClasses=nil;
        [NSApp stopModal];
    }
}

- (void)markLabelAtIndex:(NSNumber *)ndx
{
    NSUInteger index=[ndx integerValue];
    static NSUInteger lastLabelMarked=0;
    index=index%8;

    [lock lock];
    
    if (index==lastLabelMarked) {
        [lock unlock];
        return;
    }
    
    [stepsLabels[index] setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]]];
    [stepsLabels[lastLabelMarked] setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    
    [self.imageView setNeedsDisplay:YES];
    
    lastLabelMarked=index;
    if (self.glyphsFound)
        [self.glyphsCountLabel setStringValue:[NSString stringWithFormat:@"%lu",self.glyphsFound.count,nil]];
    
    [lock unlock];
    
}

- (void)resetNetwork:(id)sender
{
    self.sigmaAndEpsilonDecreaseFactor=.92;
    self.maximumNumberOfExamples=1.;
    self.myKohonenNetwork.epsilon=.6;
    self.myKohonenNetwork.sigma=.407*self.sigmaSlider.maxValue;
}

- (void)recomputeLines:(id)sender
{
    [self displaySpinningIndicator];
    [self performSelectorInBackground:@selector(recomputeLinesInternal) withObject:nil];
}

- (void)resetLines:(id)sender
{
    self.linesDetectionThreshold=0.975;
    [self recomputeLines:sender];
}

- (void)done:(id)sender
{
    [sender setEnabled:NO];
    if (processRunning) {
        [self displaySpinningIndicator];
        cancelFlag=YES;
    } else {
        [NSApp stopModal];
    }
   
}

- (void)enterScanningMode
{
    // change labels & so on
    [stepsLabels[6] setStringValue:@"▶ Identify characters..."];
    [self.epsilonSlider setEnabled:NO];
    [self.epsilonSlider setHidden:YES];
    [self.sigmaSlider setEnabled:NO];
    [self.sigmaSlider setHidden:YES];
    [self.decreaseFactorSlider setEnabled:NO];
    [self.decreaseFactorSlider setHidden:YES];
    [self.examplesSlider setEnabled:NO];
    [self.examplesSlider setHidden:YES];
    [stepsLabels[7] setHidden:YES];
    [self.startNetworkButton setEnabled:NO];
    [self.startNetworkButton setHidden:YES];
    [self.resetNetworkButton setEnabled:NO];
    [self.resetNetworkButton setHidden:YES];
    [self.sortButton setHidden:YES];
    for (NSUInteger i=20; i<24; ++i) {
        [[self.window.contentView viewWithTag:i] setHidden:YES];
    }
    _scanningMode=YES;
}

- (void)exitScanningMode
{
    // change labels & so on
    [stepsLabels[6] setStringValue:@"▶ Classify by similarity"];
    [self.epsilonSlider setEnabled:YES];
    [self.epsilonSlider setHidden:NO];
    [self.sigmaSlider setEnabled:YES];
    [self.sigmaSlider setHidden:NO];
    [self.decreaseFactorSlider setEnabled:YES];
    [self.decreaseFactorSlider setHidden:NO];
    [self.examplesSlider setEnabled:YES];
    [self.examplesSlider setHidden:NO];
    [stepsLabels[7] setHidden:NO];
    [self.startNetworkButton setEnabled:YES];
    [self.startNetworkButton setHidden:NO];
    [self.resetNetworkButton setEnabled:YES];
    [self.resetNetworkButton setHidden:NO];
    [self.sortButton setHidden:NO];
    for (NSUInteger i=20; i<24; ++i) {
        [[self.window.contentView viewWithTag:i] setHidden:NO];
    }
    _scanningMode=NO;
}

- (void)sortItems:(id)sender
{
    [self.glyphsClasses sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 label] compare:[obj2 label]];
    }];
    [self.glyphsClassesController rearrangeObjects];
}

#pragma mark - Main processes -

- (void)mainProcessInternal
{
    // look for connected components...
    [self performSelectorOnMainThread:@selector(markLabelAtIndex:) withObject:[NSNumber numberWithInteger:1] waitUntilDone:YES];
    
    [self.progressIndicator setIndeterminate:NO];
    [self.progressIndicator setDoubleValue:0.];
    
    // load connected components
    self.glyphsFound=[self.imageMatrix connectedComponentsWithCallback:^BOOL(CGFloat pc) {
        [self.progressIndicator setDoubleValue:pc];
        return cancelFlag;
    }];
    
    if (cancelFlag) {
        self.glyphsFound=nil;
        [NSApp stopModal];
        return;
    }
    
    // classify and remove components that are not glyphs...
    [self performSelectorOnMainThread:@selector(markLabelAtIndex:) withObject:[NSNumber numberWithInteger:2] waitUntilDone:YES];
    
    [self.progressIndicator setIndeterminate:YES];
    [self.progressIndicator startAnimation:self];
    
    // prepare a set of rects that are lines ranges
    NSUInteger num=self.linesDetected.count;
    NSRect rects[num];
    NSRange ranges[num];
    for (NSUInteger i=0; i<num; ++i) {
        ranges[i]=[[self.linesDetected objectAtIndex:i] rangeValue];
        rects[i]=CGRectMake(0., (CGFloat)ranges[i].location, self.image.size.width, (CGFloat)ranges[i].length);
    }
    
    // scan all the components, prepare a dictionary line by line
    self.glyphsByLine=[[[NSMutableDictionary alloc] initWithCapacity:self.linesDetected.count] autorelease];
    
    for (NNGlyph *cc in [NSSet setWithSet:self.glyphsFound]) {
        // remove too small components
        if (![cc sizeGreaterThanFractionOfRect:M_GLYPH_FRACTION]) {
            [lock lock];
            [self.glyphsFound removeObject:cc];
            [lock unlock];
        } else {
            
            // remove those that are located outside lines
            NSInteger touchedLine=NSNotFound;
            NSUInteger maxSize=0;
            for (NSUInteger i=0; i<num; ++i) {
                
                
                // and assign to each glyph the line that has the biggest intersection
                NSRect intersection=NSIntersectionRect(cc.rect, rects[i]);
                NSUInteger size=(NSUInteger)(intersection.size.width*intersection.size.height);
                
                if (size>maxSize) {
                    maxSize=size;
                    touchedLine=i;
                    break;
                }
                
            }
            
            if (touchedLine==NSNotFound) {
                [lock lock];
                [self.glyphsFound removeObject:cc];
                [lock unlock];
            } else {
                cc.line=[self.linesDetected objectAtIndex:touchedLine];
                
                if (cc.rect.size.height<M_MINIMUM_GLYPH_SIZE*cc.line.rangeValue.length) {
                    [lock lock];
                    [self.glyphsFound removeObject:cc];
                    [lock unlock];
                } else {
                    
                    // add to the right list
                    NSMutableArray *items=[self.glyphsByLine objectForKey:cc.line];
                    
                    if (!items) {
                        items=[[NSMutableArray alloc] initWithCapacity:100];
                        [self.glyphsByLine setObject:[items autorelease] forKey:cc.line];
                    }
                    
                    // enqueue
                    [items addObject:cc];
                }
                
            }
            
        }
    }
    
    if (cancelFlag) {
        self.glyphsFound=nil;
        self.linesDetected=nil;
        self.glyphsByLine=nil;
        [NSApp stopModal];
        return;
    }
    
    // identify components that are weakly linked and split into two parts
    [self performSelectorOnMainThread:@selector(markLabelAtIndex:) withObject:[NSNumber numberWithInteger:3] waitUntilDone:YES];
    
    [self.progressIndicator stopAnimation:self];
    [self.progressIndicator setDoubleValue:0.];
    [self.progressIndicator setIndeterminate:NO];
    
    CGFloat progress=0;
    if ([(NSButton *)stepsLabels[3] state]==NSOnState) {
        for (NSValue *line in self.linesDetected) {
            NSMutableArray *lineGlyphs=[self.glyphsByLine objectForKey:line];
            
            for (NSUInteger i=0; i<lineGlyphs.count; ++i) {
                
                NNGlyph *this=[lineGlyphs objectAtIndex:i];
                NSUInteger x,norm;
                
                norm=[this findHorizontalMinimum:&x
                                         inRange:NSMakeRange(.1*this.rect.size.width, .8*this.rect.size.width)
                                     greaterThan:this.rect.size.height*M_SPLITTING_LOWER_THRESHOLD];
                
                // check if it's <5
                if (norm!=NSNotFound && norm<=this.rect.size.height*M_SPLITTING_UPPER_THRESHOLD) {
                    
                    // split!
                    NSArray *arr=[this splitAtX:x];
                    
                    if ([(NNGlyph *)[arr objectAtIndex:0] sizeGreaterThanFractionOfRect:M_GLYPH_FRACTION] &&
                        [(NNGlyph *)[arr objectAtIndex:1] sizeGreaterThanFractionOfRect:M_GLYPH_FRACTION]) {
                        
                        // ok replace this with the first and append the last two
                        [lock lock];
                        [self.glyphsFound removeObject:this];
                        [self.glyphsFound addObjectsFromArray:arr];
                        [lock unlock];
                        [lineGlyphs removeObjectAtIndex:i]; --i;
                        [lineGlyphs addObjectsFromArray:arr];
                        
                    }
                    
                }
                
                [self.progressIndicator setDoubleValue:progress/(CGFloat)self.glyphsFound.count];
                
                ++progress;
            }
            
            if (cancelFlag) {
                self.glyphsFound=nil;
                self.linesDetected=nil;
                self.glyphsByLine=nil;
                [NSApp stopModal];
                return;
            }
            
        }
    }
        
    // sort all the items, from the leftmost to the rightmost
    for (id key in self.glyphsByLine.allKeys) {
        NSMutableArray *arr=[self.glyphsByLine objectForKey:key];
        [arr sortUsingSelector:@selector(compare:)];
    }
    
    // scan all the glyphs, join those that have the barycenter inside another glyph's rectanle
    
    // merge glyphs that might form a single symbol...
    [self performSelectorOnMainThread:@selector(markLabelAtIndex:) withObject:[NSNumber numberWithInteger:4] waitUntilDone:YES];

    
    [self.progressIndicator setDoubleValue:0.];
    progress=0.;
    
    if ([(NSButton *)stepsLabels[4] state]==NSOnState) {
        for (NSValue *line in self.linesDetected) {
            NSMutableArray *lineGlyphs=[self.glyphsByLine objectForKey:line];
            
            for (NSUInteger i=0; i<lineGlyphs.count; ++i) {
                
                NNGlyph *this=[lineGlyphs objectAtIndex:i];
                
                // loop in the remaining items!
                for (NSUInteger j=i+1; j<lineGlyphs.count; ++j) {
                    
                    NNGlyph *other=[lineGlyphs objectAtIndex:j];
                    
                    // check if the barycenters are one inside another
                    BOOL join=NSPointInRect(other.barycenter, this.rect) || NSPointInRect(this.barycenter, other.rect);
                    
                    if (!join) {
                        
                        // check if it's something like the dot over the i
                        if (other.barycenter.y<this.rect.origin.y &&
                            other.barycenter.x>=this.rect.origin.x &&
                            other.barycenter.x<=this.rect.origin.x+this.rect.size.width) {
                            
                            join=YES;
                            
                        } else if (this.barycenter.y<other.rect.origin.y &&
                                   this.barycenter.x>=other.rect.origin.x &&
                                   this.barycenter.x<=other.rect.origin.x+other.rect.size.width) {
                            
                            join=YES;
                        }
                    }
                    
                    if (join) {
                        
                        // these two should be merged
                        NNGlyph *merged=[NNGlyph connectedComponentByMerging:this
                                                                        with:other];
                        
                        [lock lock];
                        [self.glyphsFound removeObject:this];
                        [self.glyphsFound removeObject:other];
                        [self.glyphsFound addObject:merged];
                        [lock unlock];
                        
                        [lineGlyphs replaceObjectAtIndex:i withObject:merged];
                        [lineGlyphs removeObjectAtIndex:j];
                        
                        // reset loop!!
                        this=merged; j=i;
                        
                    }
                }
                
                [self.progressIndicator setDoubleValue:progress/(CGFloat)self.glyphsFound.count];
                
                ++progress;
            }
            
            if (cancelFlag) {
                self.glyphsFound=nil;
                self.linesDetected=nil;
                self.glyphsByLine=nil;
                [NSApp stopModal];
                return;
            }
            
        }
    }
    
    // glyphs floating over other glyphs must be associated.
    // merge floating glyphs that might form a single symbol...
    [self performSelectorOnMainThread:@selector(markLabelAtIndex:) withObject:[NSNumber numberWithInteger:5] waitUntilDone:YES];

    
    [self.progressIndicator setDoubleValue:0.];
    progress=0.;
    
    for (NSValue *line in self.linesDetected) {
        NSMutableArray *lineGlyphs=[self.glyphsByLine objectForKey:line];
        
        NNGlyph *prev=nil;
        NNGlyph *this=nil;
        NNGlyph *next=(lineGlyphs.count>0 ? [lineGlyphs objectAtIndex:0] : nil);
        
        for (NSUInteger i=1; i<lineGlyphs.count; ++i) {
            
            prev=this;
            this=next;
            next=(i<lineGlyphs.count-1 ? [lineGlyphs objectAtIndex:i+1] : nil);
            
            // check if "this" it's floating over any other glyph
            CGFloat prevDist=INFINITY;
            CGFloat nextDist=INFINITY;
            // to check if it's floating, we consider the barycenter of the floating glyph. this
            // must be over the other glyph. besides, the other glyph cannot have the barycenter
            // inside the floating glyph (otherwise strange things happen, I can provide counter-
            // examples if you're not convinced).
            if (prev && prev.barycenter.y<this.rect.origin.y && this.barycenter.y>prev.rect.origin.y+prev.rect.size.height)
                prevDist=this.rect.origin.x-prev.rect.origin.x-prev.rect.size.width;
            if (next && next.barycenter.y<this.rect.origin.y && this.barycenter.y>next.rect.origin.y+next.rect.size.height)
                nextDist=next.rect.origin.x-this.rect.size.width-this.rect.origin.x;
            
            // choose the nearest, but can't go further than "this.rect.size.width". this is
            // another test. test using fabs(), because if for some reason (related to sorting alg.)
            // prev>this or next<this, we could have unacceptable negative distances.
            NNGlyph *candidate=nil;
            if (isfinite(prevDist)) {
                if (prevDist<nextDist) {
                    candidate=(fabs(prevDist)<this.rect.size.width ? prev : nil);
                } else if (isfinite(nextDist)) {
                    candidate=(fabs(nextDist)<this.rect.size.width ? next : nil);
                }
            } else {
                if (isfinite(nextDist)) {
                    candidate=(fabs(nextDist)<this.rect.size.width ? next : nil);
                }
            }
            
            // join if necessary
            if (candidate) {
                
                NNGlyph *merged=[NNGlyph connectedComponentByMerging:this
                                                                with:candidate];
                
                [lock lock];
                [self.glyphsFound removeObject:this];
                [self.glyphsFound removeObject:candidate];
                [self.glyphsFound addObject:merged];
                [lock unlock];
                
                [lineGlyphs replaceObjectAtIndex:i-1 withObject:merged];
                this=merged;
                
                if (candidate==prev) {
                    [lineGlyphs removeObject:prev];
                    if (next)
                        --i;
                } else {
                    [lineGlyphs removeObject:next];
                    next=(i<lineGlyphs.count-1 ? [lineGlyphs objectAtIndex:i+1] : nil);
                }
                
            }
            
            [self.progressIndicator setDoubleValue:progress/(CGFloat)self.glyphsFound.count];
            
            ++progress;
        }
        
        if (cancelFlag) {
            self.glyphsFound=nil;
            self.linesDetected=nil;
            self.glyphsByLine=nil;
            [NSApp stopModal];
            return;
        }

    }
    
    [self performSelectorOnMainThread:@selector(markLabelAtIndex:) withObject:[NSNumber numberWithInteger:6] waitUntilDone:YES];
    
    if (!self.scanningMode) {
        
        processRunning=NO;
        
        [self.progressIndicator setDoubleValue:1.];
                
        [self.startNetworkButton setEnabled:YES];
        [self.epsilonSlider setEnabled:YES];
        [self.resetNetworkButton setEnabled:YES];
        [self.sigmaSlider setEnabled:YES];
        [self.examplesSlider setEnabled:YES];
        [self.decreaseFactorSlider setEnabled:YES];
        [(NSTextField *)stepsLabels[6] setTextColor:[NSColor controlTextColor]];
        [(NSTextField *)stepsLabels[7] setTextColor:[NSColor controlTextColor]];
        
        self.linesDetected=nil;
        self.glyphsByLine=nil;

    } else {
        
        // sort all the items, from the leftmost to the rightmost
        for (id key in self.glyphsByLine.allKeys) {
            NSMutableArray *arr=[self.glyphsByLine objectForKey:key];
            [arr sortUsingSelector:@selector(compare:)];
        }
        
        NSMutableString *text=[[NSMutableString alloc] initWithCapacity:1000];
        
        // now line by line scan using classes
        CGFloat lineStep=1./(double)self.linesDetected.count;
        CGFloat linesDone=0.;
        
        [self.progressIndicator setDoubleValue:0.];
        
        for (NSValue *line in self.linesDetected) {
            
            NSArray *glyphs=[self.glyphsByLine objectForKey:line];
            
            // compute average distance to identify spaces
            CGFloat avg=0.;
            for (NSUInteger i=1; i<glyphs.count; ++i) {
                NNGlyph *old=[glyphs objectAtIndex:i-1];
                NNGlyph *this=[glyphs objectAtIndex:i];
                avg+=this.rect.origin.x-old.rect.origin.x-old.rect.size.width;
            }
            avg/=(double)(glyphs.count-1);
            avg=avg+.5*fabs(avg); //that's the threshold            
            
            NNGlyph *old=nil;
            for (NSUInteger i=0; i<glyphs.count; ++i) {
             
                NNGlyph *glyph=(NNGlyph *)[glyphs objectAtIndex:i];
                
                NNGlyphsClass *bestClass=nil;
                NNGlyphsClass *bestClassWithoutRatio=nil;
                
                CGFloat bestResult=-INFINITY;
                CGFloat bestResultWithoutRatio=-INFINITY;
                
                CGFloat glyphRatio=glyph.rect.size.width/glyph.rect.size.height;
                
                for (NNGlyphsClass *cls in self.glyphsClasses) {
                    
                    CGFloat expRatio=cls.glyphsCommonSize.width/cls.glyphsCommonSize.height;
                    CGFloat ratio=expRatio/glyphRatio;
                    
                    [glyph expandImageToSize:cls.glyphsCommonSize];
                    [glyph computeInputVectorForSize:NSMakeSize(M_NETWORK_INPUT_X, M_NETWORK_INPUT_Y)];
                    
                    CGFloat result=[cls.network resultForInput:glyph.inputVector];
                    result=(result-cls.averageOnOtherGlyphs)/(cls.averageOnGlyphs-cls.averageOnOtherGlyphs);
                    
                    if (result>bestResultWithoutRatio) {
                        bestClassWithoutRatio=cls;
                        bestResultWithoutRatio=result;
                    }
                    
                    if (ratio<0.75 || ratio>1.21) continue;
                    
                    if (result>bestResult) {
                        bestClass=cls;
                        bestResult=result;
                    }

                }
                
                if (old) {
                    if (glyph.rect.origin.x>old.rect.origin.x+old.rect.size.width+avg)
                        [text appendString:@" "];
                }
                
                if (bestClass) {
                    [text appendString:bestClass.label];
                } else if (bestClassWithoutRatio) {
                    [text appendString:bestClassWithoutRatio.label];
                } else {
                    [text appendString:@"?"];
                }
                
                [self.progressIndicator setDoubleValue:lineStep*(linesDone+((double)i)/(double)glyphs.count)];
                
                if (cancelFlag) {
                    self.glyphsFound=nil;
                    self.linesDetected=nil;
                    self.glyphsByLine=nil;
                    [text release];
                    [NSApp stopModal];
                    return;
                }
                
                old=glyph;
                
            }
            
            [text appendString:@"\n"];
            
            linesDone+=1.;
            [self.progressIndicator setDoubleValue:linesDone*lineStep];
            
        }
        
        [self.progressIndicator setDoubleValue:1.];
        
        [self.outputField setString:text];
        [self.outputField.superview.superview setHidden:NO];
        [self.imageView setHidden:YES];
        
        [self performSelectorOnMainThread:@selector(markLabelAtIndex:) withObject:[NSNumber numberWithInteger:7] waitUntilDone:YES];

        [text release];
        
        processRunning=NO;
        
        [self.doneButton setEnabled:YES];
        [self.cancelButton setEnabled:NO];
        
    }
    
    // discard everything unnecessary
    self.imageMatrix=nil;
    
}

- (void)neuralNetworkProcessInternal
{
    /*
     
     This routine does the following:
     - use a kohonen network with input size 2, M_KN_SIZE_CLUSTERING (8) neurons, without weights normalization, to classify the sizes of the inputs
     - train it with the subset specified by the user, a constant epsilon and sigma but the decrease factor set by the user
     - clusterize glyphs basing on the just trained network to avoid situations such as glyphs very different in size being passed to the same network, to improve recognition
     - delete clusters with less than 5% of the examples and join those that have a width or height within a tolerance of 15%.
     - for each cluster train a kohonen network with the parameters specified by the user.
     - then use the network to group similar characters
     */
    
    [self performSelectorOnMainThread:@selector(setGlyphsClasses:)
                           withObject:nil
                        waitUntilDone:YES];
    
    // update sigma and epsilon
    [self setSigmaAndEpsilonDecreaseFactor:self.sigmaAndEpsilonDecreaseFactor];
    
    NSMutableArray *examples=[[NSMutableArray alloc] initWithArray:[self.glyphsFound allObjects]];
    NSUInteger max=self.maximumNumberOfExamples*self.glyphsFound.count;
    
    // first of all we need to cluster examples by size.
    // use a neural network with size 2 (x and y) without normalization
    NNMyKohonenNetwork *clusterizer=[[NNMyKohonenNetwork alloc] initWithImageSize:NSMakeSize(1., 2.)
                                                                      neurons:M_KN_SIZE_CLUSTERING];
        
    
    // some hardcoded parameter found running some test
    clusterizer.epsilon=.5;
    clusterizer.epsilonDecreaseFactor=self.myKohonenNetwork.epsilonDecreaseFactor;
    clusterizer.sigma=1.4;
    clusterizer.sigmaDecreaseFactor=self.myKohonenNetwork.sigmaDecreaseFactor;
    clusterizer.normalizeInput=NO;

    [self.progressIndicator setIndeterminate:NO];
    [self.progressIndicator setDoubleValue:0.];
        
    // train the network
    for (NSUInteger i=0; i<max; ++i) {
        NSUInteger rnd=arc4random()%examples.count;
        
        NNGlyph *example=[examples objectAtIndex:rnd];
        float size[2]={example.image.size.width, example.image.size.height};
        [clusterizer trainWinnerWithExample:size];
        
        [examples removeObject:example];
        
        [self.progressIndicator setDoubleValue:.2*((double)i)/(double)max];
        
        if (cancelFlag) {
            [examples release];
            [clusterizer release];
            self.glyphsFound=nil;
            [NSApp stopModal];
            return;
        }

    }
    
    // now clusterize all the examples by size
    NSMutableArray *clusters=[[NSMutableArray alloc] initWithCapacity:M_KN_SIZE_CLUSTERING];
    NSSize maxSizeInCluster[M_KN_SIZE_CLUSTERING];

    // initialize an array of mutable arrays
    for (NSUInteger i=0; i<M_KN_SIZE_CLUSTERING; ++i) {
        [clusters addObject:[NSMutableArray arrayWithCapacity:100]];
        maxSizeInCluster[i]=NSMakeSize(-INFINITY, -INFINITY);
    }
    
    // assign to each glyph one cluster
    CGFloat progress=0.;
    for (NNGlyph *g in self.glyphsFound) {
        float size[2]={g.image.size.width, g.image.size.height};
        [(NSMutableArray *)[clusters objectAtIndex:[clusterizer winnerForInput:size]] addObject:g];
        
        [self.progressIndicator setDoubleValue:.2+.4*(progress/(double)self.glyphsFound.count)];
        ++progress;
        
        if (cancelFlag) {
            [examples release];
            [clusterizer release];
            [clusters release];
            self.glyphsFound=nil;
            [NSApp stopModal];
            return;
        }

    }
    
    // now compute the max size in each set
    for (NSUInteger i=0; i<M_KN_SIZE_CLUSTERING; ++i)
        for (NNGlyph *g in [clusters objectAtIndex:i]) {
            if (g.image.size.width>maxSizeInCluster[i].width)
                maxSizeInCluster[i].width=g.image.size.width;
            if (g.image.size.height>maxSizeInCluster[i].height)
                maxSizeInCluster[i].height=g.image.size.height;
        }
    
    // join all the clusters with too similar sizes.
    // this method has complexity O(n^2) but M_KN_SIZE_CLUSTERING must be small, at most 10
    
    BOOL mustRemove[M_KN_SIZE_CLUSTERING];
    
    for (NSUInteger i=0; i<M_KN_SIZE_CLUSTERING; ++i) {
        mustRemove[i]=NO;
        
        // get the size
        CGFloat size=maxSizeInCluster[i].width*maxSizeInCluster[i].height;
        
        // loop and compare to the next sizes
        NSUInteger nearest=i;
        CGFloat nearestDistance=INFINITY;
        for (NSUInteger j=i+1; j<M_KN_SIZE_CLUSTERING; ++j) {
            CGFloat sizeJ=maxSizeInCluster[j].width*maxSizeInCluster[j].height;
            if (fabs(sizeJ-size)<fabs(nearestDistance)) {
                nearest=j;
                nearestDistance=sizeJ-size;
            }
        }
                
        // check if there is anything to join with. the number of pixels must be in range 80-120% relative to current size
        // and the same condition must hold for width and height
        if (nearest!=i &&
            fabs(nearestDistance)<M_SIZE_CLUSTER_TOLERANCE*(1.+M_SIZE_CLUSTER_TOLERANCE)*size &&
            fabs(maxSizeInCluster[i].width-maxSizeInCluster[nearest].width)<M_SIZE_CLUSTER_TOLERANCE*maxSizeInCluster[i].width &&
            fabs(maxSizeInCluster[i].height-maxSizeInCluster[nearest].height)<M_SIZE_CLUSTER_TOLERANCE*maxSizeInCluster[i].height) {
            
            // copy everything into j
            [(NSMutableArray *)[clusters objectAtIndex:nearest] addObjectsFromArray:[clusters objectAtIndex:i]];
            maxSizeInCluster[nearest]=NSMakeSize(fmax(maxSizeInCluster[i].width, maxSizeInCluster[nearest].width),
                                                 fmax(maxSizeInCluster[i].height, maxSizeInCluster[nearest].height));
            mustRemove[i]=YES;
        } else {
            
            // remove this also if has too few examples!
            if ([(NSMutableArray *)[clusters objectAtIndex:i] count]<.05*max) {
                mustRemove[i]=YES;
            }
            
        }
        
    }
    
    // now remove all the clusters that has to be removed
    for (NSInteger i=M_KN_SIZE_CLUSTERING-1; i>=0; --i) {
        if (mustRemove[i]) {
            [clusters removeObjectAtIndex:i];
        } else {
            // ensure all the glyphs contained have the same size!
            for (NNGlyph *g in [clusters objectAtIndex:i]) {
                [g expandImageToSize:maxSizeInCluster[i]];
            }
        }
    }
    
    // prepare space for character classes
    NSMutableArray *classes=[[NSMutableArray alloc] initWithCapacity:M_KN_GLYPH_CLUSTERING*clusters.count];
    NSMutableArray *classesForCluster=[[NSMutableArray alloc] initWithCapacity:M_KN_GLYPH_CLUSTERING];

    progress=0.;
    for (NSMutableArray *cluster in clusters) {
        
        // prepare network
        [self.myKohonenNetwork resetNetwork];
        
        // define max again and examples
        max=self.maximumNumberOfExamples*cluster.count;
        [examples removeAllObjects];
        [examples addObjectsFromArray:cluster];
        
        // loop and pick one at random
        for (NSUInteger i=0; i<max; ++i) {
            NSUInteger rnd=arc4random()%examples.count;
            [self.myKohonenNetwork trainWinnerWithImage:[(NNGlyph *)[examples objectAtIndex:rnd] image]];
            [examples removeObjectAtIndex:rnd];
            
            [self.progressIndicator setDoubleValue:.6+.4*((progress+.5*(((double)i)/(double)max))/(double)clusters.count)];
        }
        
        // define a temporary mutable array and fill it
        [classesForCluster removeAllObjects];
        for (NSUInteger i=0; i<M_KN_GLYPH_CLUSTERING; ++i)
            [classesForCluster addObject:[[[NNGlyphsClass alloc] init] autorelease]];
        
        // loop and assign to each subset
        CGFloat progress2=0.;
        for (NNGlyph *g in cluster) {            
            [[(NNGlyphsClass *)[classesForCluster objectAtIndex:[self.myKohonenNetwork winnerForImage:[g image]]] glyphs] addObject:g];
            
            [self.progressIndicator setDoubleValue:.6+.4*((.5+progress+.5*(progress2/(double)cluster.count))/(double)clusters.count)];
            ++progress2;
        }
        
        // remove empty classes
        for (NSUInteger i=0; i<classesForCluster.count; ++i)
            if ([[classesForCluster objectAtIndex:i] count]==0) {
                [classesForCluster removeObjectAtIndex:i];
                --i;
            }
        
        // add to main list
        [classes addObjectsFromArray:classesForCluster];
        
        ++progress;
        [self.progressIndicator setDoubleValue:.6+.4*(progress/(double)clusters.count)];
        
        if (cancelFlag) {
            [classes release];
            [classesForCluster release];
            [examples release];
            [clusterizer release];
            [clusters release];
            self.glyphsFound=nil;
            [NSApp stopModal];
            return;
        }

    }
    
    processRunning=NO;
    
    // clear
    [classesForCluster release];
    [examples release];
    [clusterizer release];
    [clusters release];
    
    [self performSelectorOnMainThread:@selector(setGlyphsClasses:)
                           withObject:classes
                        waitUntilDone:YES];
    
    [classes release];
    
    [self performSelectorOnMainThread:@selector(markLabelAtIndex:) withObject:[NSNumber numberWithInteger:7] waitUntilDone:YES];
    [self.progressIndicator setDoubleValue:1.];
    
    [self.startNetworkButton setEnabled:YES];
    [self.epsilonSlider setEnabled:YES];
    [self.resetNetworkButton setEnabled:YES];
    [self.sigmaSlider setEnabled:YES];
    [self.examplesSlider setEnabled:YES];
    [self.decreaseFactorSlider setEnabled:YES];
    [self.doneButton setEnabled:YES];
    [self.sortButton setEnabled:YES];
    [(NSTextField *)stepsLabels[6] setTextColor:[NSColor controlTextColor]];
    [(NSTextField *)stepsLabels[7] setTextColor:[NSColor controlTextColor]];
    
    //animate window
    [self performSelectorOnMainThread:@selector(resizeWindow) withObject:nil waitUntilDone:NO];
    
}

#pragma mark - Drag and Drop -

-(NSImage *)collectionView:(NSCollectionView *)collectionView draggingImageForItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset
{
    NSView *view=[collectionView itemAtIndex:[indexes firstIndex]].view;
    
    // get view relative to screen
    NSRect frameOnScreen = [view.window convertRectToScreen:[view convertRect:view.bounds toView:nil]];
    NSPoint loc=[NSEvent mouseLocation];

    loc.x=.5*frameOnScreen.size.width+frameOnScreen.origin.x-loc.x;
    loc.y=.5*frameOnScreen.size.height+frameOnScreen.origin.y-loc.y;
    
    NSImage *img=[collectionView draggingImageForItemsAtIndexes:indexes withEvent:event offset:dragImageOffset];

    (*dragImageOffset)=loc;
    
    return img;
    
}

- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    NSString *type=@"com.SpakSW.NeuralNetworks.GlyphsClass";
    [pasteboard declareTypes:[NSArray arrayWithObject:type] owner:nil];
    
    draggedItem=(NNGlyphsClassView *)[collectionView itemAtIndex:[indexes firstIndex]];

    [pasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:draggedItem.representedObject] forType:type];
    
    [draggedItem.headerView setDraggingPasteboardToSkip:pasteboard];
    
    return YES;
}

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    NSString *type=@"com.SpakSW.NeuralNetworks.Glyph";
    if (![[[draggingInfo draggingPasteboard] types] containsObject:type])
        return NSDragOperationNone;
    
    return NSDragOperationMove;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    // create a new class and insert
    NSArray *items=[NSKeyedUnarchiver unarchiveObjectWithData:[[draggingInfo draggingPasteboard] dataForType:@"com.SpakSW.NeuralNetworks.Glyph"]];
    
    NNGlyphsClass *newClass=[[NNGlyphsClass alloc] init];
    [newClass.glyphs addObjectsFromArray:items];
    
    [self.glyphsClassesController insertObject:newClass atArrangedObjectIndex:index];
    
    [newClass release];
    
    return YES;
}


- (void)collectionView:(NSCollectionView *)collectionView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint dragOperation:(NSDragOperation)operation
{    
    
    [draggedItem.headerView setDraggingPasteboardToSkip:nil];
    
    if (operation==NSDragOperationMove || (operation==NSDragOperationNone && !session.animatesToStartingPositionsOnCancelOrFail)) {
        [self.glyphsClassesController removeObject:draggedItem.representedObject];
    }
}

@end
