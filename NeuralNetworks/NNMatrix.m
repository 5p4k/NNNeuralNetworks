//
//  NNMatrix.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 07/05/12.
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

#import "NNMatrix.h"
#import "NNGlyph.h"

@interface NNMatrix ()
+ (NSArray *)extractRangesFromFloats:(float *)    data
                               count:(NSUInteger) count
                       minimumLength:(float)      length
                      lowerThreshold:(float)      lower
                      upperThreshold:(float)      upper;
@end

@implementation NNMatrix
@synthesize width=_width, height=_height, parentMatrix=_parentMatrix;

- (id)initWithImage:(NSImage *)img
{
    if ((self=[super init])) {
        _width=(NSUInteger)img.size.width;
        _height=(NSUInteger)img.size.height;
        
        matrix=malloc(sizeof(float)*_width*_height);
        
        // create a NSImageRep with the right format, wrapping matrix
        NSBitmapImageRep *rep=[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                      pixelsWide:_width
                                                                      pixelsHigh:_height
                                                                   bitsPerSample:sizeof(float)*8
                                                                 samplesPerPixel:1
                                                                        hasAlpha:NO
                                                                        isPlanar:NO
                                                                  colorSpaceName:NSCalibratedWhiteColorSpace
                                                                    bitmapFormat:NSFloatingPointSamplesBitmapFormat
                                                                     bytesPerRow:_width*sizeof(float)
                                                                    bitsPerPixel:sizeof(float)*8];
        
        // draw the image into a graphic context mapped on the bitmap rep
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];
        
        [img drawAtPoint:NSMakePoint(0., 0.)
                fromRect:NSMakeRect(0., 0., img.size.width, img.size.height)
               operation:NSCompositeCopy
                fraction:1.];
                
        [NSGraphicsContext restoreGraphicsState];
        
        // copy data from rep.
        memcpy(matrix, rep.bitmapData, sizeof(float)*_width*_height);
        
        [rep release];
        
    }
    
    return self;
}

- (BOOL)hasNormOfRows
{
    return normOfRows!=nil;
}

- (void)computeNormOfRows
{
    if (!normOfRows)
        normOfRows=malloc(sizeof(float)*self.height);
    
    float min=INFINITY;
    float max=-INFINITY;
    
    for (NSUInteger i=0; i<self.height; ++i) {
        
        normOfRows[i]=cblas_snrm2((int)self.width, &matrix[i*self.width], 1);
        
        if (normOfRows[i]<min) min=normOfRows[i];
        if (normOfRows[i]>max) max=normOfRows[i];
        
    }
    
    // scale everything to clamp it into 0-1
    for (NSUInteger i=0; i<self.height; ++i)
        normOfRows[i]-=min;
    
    cblas_sscal((int)self.height, 1./(max-min), normOfRows, 1);
}


+ (NSArray *)extractRangesFromFloats:(float *)    data
                               count:(NSUInteger) count
                       minimumLength:(float)      length
                      lowerThreshold:(float)      lower
                      upperThreshold:(float)      upper
{
    NSMutableArray *ranges=[[NSMutableArray alloc] initWithCapacity:20];
    NSRange current;
    
    // some flags
    BOOL locationFound=NO;
    NSUInteger lastStatus=1;
    NSInteger gtLower=-1;
    NSInteger ltLower=-1;
    NSInteger gtUpper=-1;
    NSInteger ltUpper=-1;
    
    // loop and search for local minima
    for (NSUInteger k=0; k<count; ++k) {
        
        // compute the new status and the flags
        NSUInteger newStatus=0;
        if (data[k]>upper) newStatus=1;
        if (data[k]<=upper && data[k]>=lower) newStatus=2;
        if (data[k]<lower) newStatus=3;
        
        // check if sth changed
        if (newStatus!=lastStatus) {
            
            // update flags.
            switch (newStatus) {
                case 1: // >upper
                    if (lastStatus==2) gtUpper=k;
                    if (lastStatus==3) { gtUpper=k; gtLower=k; }
                    break;
                    
                case 2: // upper>= >=lower
                    if (lastStatus==1) ltUpper=k;
                    if (lastStatus==3) gtLower=k;
                    break;
                    
                case 3: //<lower
                    if (lastStatus==2) ltLower=k;
                    if (lastStatus==1) { ltUpper=k; ltLower=k; }
                    break;
            }
            
            // check to define the new range
            if (!locationFound) {
                
                // we're looking for the next line.
                if (newStatus==3) {
                    
                    // that's line start
                    current.location=(NSInteger)(ltUpper>=0 ? .5*(ltUpper+ltLower) : ltLower);
                    locationFound=YES;
                    
                    // skip the minimum line height!
                    k=MAX(k,current.location+(NSUInteger)length);
                    
                }
                
            } else {
                
                // we're looking for line end.
                
                // check if we've reached threshold
                if (newStatus==1) {  
                    
                    // that's line end.
                    current.length=(NSInteger)(gtLower>=0 ? .5*(gtLower+gtUpper) : gtUpper)-current.location;
                    
                    // add to list
                    [ranges addObject:[NSValue valueWithRange:current]];
                    
                    // update currentLine
                    locationFound=NO;
                    
                }
                
            }
            
            // save status
            lastStatus=newStatus;
            
        }
        
    }
    
    // complete current line if necessary
    if (locationFound) {
        
        current.length=count-current.location;
        [ranges addObject:[NSValue valueWithRange:current]];
        
    }
    
    // now return an array!
    NSArray *output=[NSArray arrayWithArray:ranges];
    [ranges release];
    
    return output;
}

- (NSMutableSet *)connectedComponentsWithCallback:(BOOL (^)(CGFloat))cbk
{
    if (cbk) if(cbk(0.)) return nil;
    
    // use an array of unsigned int to memorize the components
    NSUInteger *arlequin=malloc(sizeof(NSUInteger)*self.width*self.height);
    memset(arlequin, 0, sizeof(NSUInteger)*self.width*self.height);
    
    // when two components get in touch, they become the same component. so if one piece is
    // indexed with index i and the other with index j, we set palette[i]=palette[j]=MAX(i,j).
    // we have a unique index for all the touched components.
    NSMutableArray *palette=[[NSMutableArray alloc] initWithCapacity:1000];
    
    // add first object
    [palette addObject:[NSNumber numberWithInt:0]];
    
    // initialize flags!
    NSUInteger colors=0;
    
    for (NSUInteger y=0; y<self.height; ++y) {
        for (NSUInteger x=0; x<self.width; ++x)
            if (matrix[y*self.width+x]<.5) {
                
                // this is a black px.
                
                // check if it its neighbours are already painted
                NSUInteger neighbourY0=0;
                NSUInteger neighbourY1=0;
                NSUInteger neighbourX=0;
                
                if (y>0) {
                    neighbourY0=arlequin[(y-1)*self.width+x];
                    if (x>0)
                        neighbourY0=MAX(neighbourY0, arlequin[(y-1)*self.width+x-1]);
                    
                    if (x<self.width-1)
                        neighbourY1=arlequin[(y-1)*self.width+x+1];
                }
                
                if (x>0)
                    neighbourX=arlequin[y*self.width+x-1];
                
                // copy from neighbours, in order
                if (neighbourX!=0)
                    arlequin[y*self.width+x]=neighbourX;
                else if (neighbourY0!=0)
                    arlequin[y*self.width+x]=neighbourY0;
                else if (neighbourY1!=0)
                    arlequin[y*self.width+x]=neighbourY1;
                else {
                    
                    // need a new color for this new connected component
                    colors++;
                    
                    arlequin[y*self.width+x]=colors;
                    
                    // store the label
                    [palette addObject:[NSNumber numberWithInteger:colors]];
                    
                }
                
                // join the components...
                NSNumber *source0=nil;
                NSNumber *source1=nil;
                NSNumber *source2=nil;
                
                // obtain three references from the neighbours
                if (neighbourX!=0 && arlequin[y*self.width+x]!=neighbourX)
                    source0=[palette objectAtIndex:neighbourX];
                
                if (neighbourY0!=0 && arlequin[y*self.width+x]!=neighbourY0)
                    source1=[palette objectAtIndex:neighbourY0];
                
                if (neighbourY1!=0 && arlequin[y*self.width+x]!=neighbourY1)
                    source2=[palette objectAtIndex:neighbourY1];
                
                if (source0!=nil || source1!=nil || source2!=nil) {
                    NSNumber *replace=[palette objectAtIndex:arlequin[y*self.width+x]];
                    
                    // perform replacement in palette! the reference to sourceJ can appear also
                    // elsewhere, not only in neighbours
                    for (NSUInteger i=0; i<palette.count; ++i) {
                        NSNumber *source=[palette objectAtIndex:i];
                        if (source==source0 || source==source1 || source==source2)
                            [palette replaceObjectAtIndex:i withObject:replace];
                    }
                }
                
            }
        
        if (cbk)
            if (cbk(.6*((CGFloat)y)/((CGFloat)self.height))) {
                [palette release];
                return nil;
            }
    }
    
    // prepare an array of nnconnectedcomponents
    NSMutableDictionary *dict=[[NSMutableDictionary alloc] initWithCapacity:palette.count];
    for (NSUInteger i=0; i<palette.count; ++i)
        if ([dict objectForKey:[palette objectAtIndex:i]]==nil) // alloc the object
            [dict setObject:[[[NNGlyph alloc] init] autorelease] forKey:[palette objectAtIndex:i]];
    
    // now replace items in palette with the right nnconnectedcomponents
    for (NSUInteger i=0; i<palette.count; ++i)
        [palette replaceObjectAtIndex:i withObject:[dict objectForKey:[palette objectAtIndex:i]]];
    
    // we don't need anymore dict
    [dict release];
    
    // now loop in the image again, and adapt the size of each nnconnectedcomponent
    for (NSUInteger y=0; y<self.height; ++y) {
        for (NSUInteger x=0; x<self.width; ++x) {
            if (arlequin[y*self.width+x]==0) continue;
            [(NNGlyph *)[palette objectAtIndex:arlequin[y*self.width+x]] expandToIncludeX:x y:y];
        }
        
        if (cbk)
            if (cbk(.6+.2*((CGFloat)y)/((CGFloat)self.height))) {
                [palette release];
                return nil;
            }
    }
    
    // alloc nsimagereps
    for (NNGlyph *cc in palette)
        [cc setupImage];
    
    // now effectively place data in the connected components
    for (NSUInteger y=0; y<self.height; ++y) {
        for (NSUInteger x=0; x<self.width; ++x) {
            if (arlequin[y*self.width+x]==0) continue;
            [(NNGlyph *)[palette objectAtIndex:arlequin[y*self.width+x]] addPointX:x y:y];
        }
        
        if (cbk)
            if (cbk(.8+.2*((CGFloat)y)/((CGFloat)self.height))) {
                [palette release];
                return nil;
            }
    }
    
    // remove the first object... it's the null nnimagerep
    [palette removeObjectAtIndex:0];
    NSMutableSet *output=[NSMutableSet setWithArray:palette];
    
    [palette release];

    if (cbk) cbk(1.);
    
    free(arlequin);
    
    return output;
}

- (void)transpose
{
    float *transpose=malloc(self.width*self.height*sizeof(float));
    
    for (NSUInteger x=0; x<self.width; ++x)
        for (NSUInteger y=0; y<self.height; ++y)
            transpose[x*self.height+y]=matrix[y*self.width+x];
    
    if (_parentMatrix) {
        [_parentMatrix release];
        _parentMatrix=nil;
    } else {
        free(matrix);
    }
    
    matrix=transpose;
    
    NSUInteger temp=self.width;
    _width=self.height;
    _height=temp;
}

- (NSDictionary *)matricesWithRanges:(NSArray *)ranges
{
    NSMutableDictionary *matrices=[[NSMutableDictionary alloc] initWithCapacity:ranges.count];
    
    for (NSUInteger i=0; i<ranges.count; ++i) {
        
        NSRange rg=[[ranges objectAtIndex:i] rangeValue];
        
        // extract matrix
        NNMatrix *newNNMatrix=[[NNMatrix alloc] init];
        newNNMatrix->matrix=&matrix[rg.location*self.width];
        newNNMatrix->_width=self.width;
        newNNMatrix->_height=rg.length;
        newNNMatrix->_parentMatrix=[self retain];

        [matrices setValue:[newNNMatrix autorelease] forKey:[ranges objectAtIndex:i]];
    }
    
    NSDictionary *output=[NSDictionary dictionaryWithDictionary:matrices];
    [matrices release];
    
    return output;
}
- (NSArray *)extractRowsWithThreshold:(float)th delta:(float)d minLength:(NSUInteger)min
{
    return [NNMatrix extractRangesFromFloats:normOfRows
                                       count:self.height
                               minimumLength:min
                              lowerThreshold:th-d
                              upperThreshold:th+d];
}
- (id)initWithWidth:(NSUInteger)w andHeight:(NSUInteger)h
{
    if ((self=[super init])) {
        matrix=malloc(sizeof(float)*w*h);
        _width=w;
        _height=h;
    }
    return self;
}

- (void)dealloc
{
    free(matrix);
    if (normOfRows)
        free(normOfRows);
    
    [_parentMatrix release];
    
    [super dealloc];
}

@end
