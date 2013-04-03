//
//  NNGlyphsClass.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 13/05/12.
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

#import "NNGlyphsClass.h"
#import "NNGlyph.h"
#import "NNFeedForwardNetwork.h"

@implementation NNGlyphsClass
@synthesize label=_label,glyphs=_glyphs,errors=_errors,network=_network,averageOnGlyphs=_averageOnGlyphs,averageOnOtherGlyphs=_averageOnOtherGlyphs,glyphsCommonSize=_glyphsCommonSize;
- (id)init
{
    self = [super init];
    if (self) {
        self.label=@"(Glyphs)";
        _glyphs=[[NSMutableArray alloc] initWithCapacity:100];
        _network=[[NNFeedForwardNetwork alloc] initWithInputSize:M_NETWORK_INPUT_X*M_NETWORK_INPUT_Y
                                                        neurons:M_FF_SCANNER];
        [_network addObserver:self forKeyPath:@"examplesGiven" options:NSKeyValueObservingOptionPrior context:NULL];
        _errors=[[NSMutableArray alloc] initWithCapacity:100];
        _averageOnGlyphs=NAN;
        _glyphsCommonSize=NSMakeSize(NAN, NAN);
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"examplesGiven"]) {
        if ([change.allKeys containsObject:NSKeyValueChangeNotificationIsPriorKey])
            [self willChangeValueForKey:@"description"];
        else
            [self didChangeValueForKey:@"description"];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    NNGlyphsClass *new=[[NNGlyphsClass alloc] init];
    [new.glyphs addObjectsFromArray:self.glyphs];
    [new->_errors addObjectsFromArray:self.errors];
    [new->_network release];
    new->_network=[self.network copyWithZone:zone];
    [new->_network addObserver:self forKeyPath:@"examplesGiven" options:NSKeyValueObservingOptionPrior context:NULL];
    new.label=self.label;
    
    return new;
}

- (void)clearErrors
{
    [self willChangeValueForKey:@"errors"];
    [_errors removeAllObjects];
    [self didChangeValueForKey:@"errors"];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_label forKey:@"NNGlyphsClass->_label"];
    [aCoder encodeObject:_glyphs forKey:@"NNGlyphsClass->_glyphs"];
    [aCoder encodeObject:_network forKey:@"NNGlyphsClass->_network"];
    [aCoder encodeObject:_errors forKey:@"NNGlyphsClass->_errors"];
    [aCoder encodeFloat:_averageOnGlyphs forKey:@"NNGlyphsClass->_averageOnGlyphs"];
    [aCoder encodeFloat:_averageOnOtherGlyphs forKey:@"NNGlyphsClass->_averageOnOtherGlyphs"];
    [aCoder encodeSize:_glyphsCommonSize forKey:@"NNGlyphsClass->_glyphsCommonSize"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self=[super init])) {
        _label=[[aDecoder decodeObjectForKey:@"NNGlyphsClass->_label"] retain];
        _glyphs=[[aDecoder decodeObjectForKey:@"NNGlyphsClass->_glyphs"] retain];
        _network=[[aDecoder decodeObjectForKey:@"NNGlyphsClass->_network"] retain];
        [_network addObserver:self forKeyPath:@"examplesGiven" options:NSKeyValueObservingOptionPrior context:NULL];
        _errors=[[aDecoder decodeObjectForKey:@"NNGlyphsClass->_errors"] retain];
        _averageOnGlyphs=[aDecoder decodeFloatForKey:@"NNGlyphsClass->_averageOnGlyphs"];
        _averageOnOtherGlyphs=[aDecoder decodeFloatForKey:@"NNGlyphsClass->_averageOnOtherGlyphs"];
        _glyphsCommonSize=[aDecoder decodeSizeForKey:@"NNGlyphsClass->_glyphsCommonSize"];
    }
    return self;
}

- (void)computeAverageOnOtherGlyphs:(NSSet *)otherGlyphs
{
    [self willChangeValueForKey:@"averageOnOtherGlyphs"];
    if (otherGlyphs.count==0) {
        _averageOnOtherGlyphs=NAN;
        [self didChangeValueForKey:@"averageOnOtherGlyphs"];
        return;
    }
    
    CGFloat avg=0.;
    for (NNGlyph *g in otherGlyphs)
        avg+=[self.network resultForInput:g.inputVector];
    
    avg=avg/(CGFloat)otherGlyphs.count;
    
    _averageOnOtherGlyphs=avg;
    
    [self didChangeValueForKey:@"averageOnOtherGlyphs"];
}

- (void)computeAverageOnGlyphs
{
    [self willChangeValueForKey:@"averageOnGlyphs"];
    if (self.glyphs.count==0) {
        _averageOnGlyphs=NAN;
        [self didChangeValueForKey:@"averageOnGlyphs"];
        return;
    }
    
    CGFloat avg=0.;
    for (NNGlyph *g in self.glyphs)
        avg+=[self.network resultForInput:g.inputVector];
    
    avg=avg/(CGFloat)self.glyphs.count;
    
    _averageOnGlyphs=avg;

    [self didChangeValueForKey:@"averageOnGlyphs"];
}

- (CGFloat)selectivityErrorOnClassesSet:(NSSet *)classes
{
    // first of all store minimum result for this network
    CGFloat min=INFINITY; NSSize sz=NSMakeSize(M_NETWORK_INPUT_X, M_NETWORK_INPUT_Y);
    for (NNGlyph *g in self.glyphs) {
        if (!g.inputVector) [g computeInputVectorForSize:sz];
        
        min=fmin(min,[self.network resultForInput:g.inputVector]);
    }
    
    // now compare with the other classes
    CGFloat max=-INFINITY;
    for (NNGlyphsClass *cls in classes) {
        if (cls==self) continue;
        
        for (NNGlyph *g in cls.glyphs) {
            if (!g.inputVector) [g computeInputVectorForSize:sz];
            
            max=fmax(max, [self.network resultForInput:g.inputVector]);
        }
    }
    
    return max-min+2.;
}
- (CGFloat)selectivityErrorOnClassesArray:(NSArray *)classes
{
    // first of all store minimum result for this network
    CGFloat min=INFINITY; NSSize sz=NSMakeSize(M_NETWORK_INPUT_X, M_NETWORK_INPUT_Y);
    for (NNGlyph *g in self.glyphs) {
        if (!g.inputVector) [g computeInputVectorForSize:sz];
        
        min=fmin(min,[self.network resultForInput:g.inputVector]);
    }
    
    // now compare with the other classes
    CGFloat max=-INFINITY;
    for (NNGlyphsClass *cls in classes) {
        for (NNGlyph *g in cls.glyphs) {
            if (!g.inputVector) [g computeInputVectorForSize:sz];
            
            max=fmax(max, [self.network resultForInput:g.inputVector]);
        }
    }
    
    return max-min+2.;
}

- (CGFloat)errorOnExamplesSet:(NSSet *)set
{
    CGFloat result=[_network errorOnExamplesSet:set];
    return result;
}

- (void)storeErrors:(NSPoint)err
{
    [self willChangeValueForKey:@"errors"];
    [_errors addObject:[NSValue valueWithPoint:err]];
    [self didChangeValueForKey:@"errors"];
}

- (CGFloat)errorOnExamplesArray:(NSArray *)arr
{
    CGFloat result=[_network errorOnExamplesArray:arr];
    return result;
}

- (void)dealloc
{
    [_network removeObserver:self forKeyPath:@"examplesGiven"];
    [_network release];
    [_label release];
    [_glyphs release];
    [_errors release];
    
    [super dealloc];
}

- (void)insertGlyphs:(NSArray *)array atIndexes:(NSIndexSet *)indexes
{
    [self willChangeValueForKey:@"count"];
    [self willChangeValueForKey:@"description"];
    if ([indexes containsIndex:0]) {
        [self willChangeValueForKey:@"aGlyph"];
    }
    
    [self willChangeValueForKey:@"averageOnGlyphs"];
    [self willChangeValueForKey:@"averageOnOtherGlyphs"];
    [self willChangeValueForKey:@"glyphsCommonSize"];
    _averageOnGlyphs=_averageOnOtherGlyphs=NAN;
    _glyphsCommonSize=NSMakeSize(NAN, NAN);

    [self.glyphs insertObjects:array atIndexes:indexes];
    
    [self didChangeValueForKey:@"glyphsCommonSize"];
    [self didChangeValueForKey:@"averageOnOtherGlyphs"];
    [self didChangeValueForKey:@"averageOnGlyphs"];

    if ([indexes containsIndex:0]) {
        [self didChangeValueForKey:@"aGlyph"];
    }
    [self didChangeValueForKey:@"description"];
    [self didChangeValueForKey:@"count"];
}

- (void)insertObject:(NNGlyph *)object inGlyphsAtIndex:(NSUInteger)index
{
    [self willChangeValueForKey:@"description"];
    [self willChangeValueForKey:@"count"];
    if (index==0) {
        [self willChangeValueForKey:@"aGlyph"];
    }
    
    [self willChangeValueForKey:@"averageOnGlyphs"];
    [self willChangeValueForKey:@"averageOnOtherGlyphs"];
    [self willChangeValueForKey:@"glyphsCommonSize"];
    _averageOnGlyphs=_averageOnOtherGlyphs=NAN;
    _glyphsCommonSize=NSMakeSize(NAN, NAN);
    
    [self.glyphs insertObject:object atIndex:index];
    
    [self didChangeValueForKey:@"glyphsCommonSize"];
    [self didChangeValueForKey:@"averageOnOtherGlyphs"];
    [self didChangeValueForKey:@"averageOnGlyphs"];

    if (index==0) {
        [self willChangeValueForKey:@"aGlyph"];
    }
    [self didChangeValueForKey:@"count"];
    [self didChangeValueForKey:@"description"];
}

- (void)removeGlyphsAtIndexes:(NSIndexSet *)indexes
{
    [self willChangeValueForKey:@"description"];
    [self willChangeValueForKey:@"count"];
    if ([indexes containsIndex:0]) {
        [self willChangeValueForKey:@"aGlyph"];
    }
    
    [self willChangeValueForKey:@"averageOnGlyphs"];
    [self willChangeValueForKey:@"averageOnOtherGlyphs"];
    [self willChangeValueForKey:@"glyphsCommonSize"];
    _averageOnGlyphs=_averageOnOtherGlyphs=NAN;
    _glyphsCommonSize=NSMakeSize(NAN, NAN);
    
    [self.glyphs removeObjectsAtIndexes:indexes];
    
    [self didChangeValueForKey:@"glyphsCommonSize"];
    [self didChangeValueForKey:@"averageOnOtherGlyphs"];
    [self didChangeValueForKey:@"averageOnGlyphs"];

    if ([indexes containsIndex:0]) {
        [self didChangeValueForKey:@"aGlyph"];
    }
    [self didChangeValueForKey:@"count"];
    [self didChangeValueForKey:@"description"];
}

- (void)removeObjectFromGlyphsAtIndex:(NSUInteger)index
{
    [self willChangeValueForKey:@"description"];
    [self willChangeValueForKey:@"count"];
    if (index==0) {
        [self willChangeValueForKey:@"aGlyph"];
    }
    
    [self willChangeValueForKey:@"averageOnGlyphs"];
    [self willChangeValueForKey:@"averageOnOtherGlyphs"];
    [self willChangeValueForKey:@"glyphsCommonSize"];
    _averageOnGlyphs=_averageOnOtherGlyphs=NAN;
    _glyphsCommonSize=NSMakeSize(NAN, NAN);
    
    [self.glyphs removeObjectAtIndex:index];
    
    [self didChangeValueForKey:@"glyphsCommonSize"];
    [self didChangeValueForKey:@"averageOnOtherGlyphs"];
    [self didChangeValueForKey:@"averageOnGlyphs"];

    if (index==0) {
        [self didChangeValueForKey:@"aGlyph"];
    }
    [self didChangeValueForKey:@"count"];
    [self didChangeValueForKey:@"description"];
}

- (void)replaceGlyphsAtIndexes:(NSIndexSet *)indexes withGlyphs:(NSArray *)array
{
    [self willChangeValueForKey:@"description"];
    [self willChangeValueForKey:@"count"];
    if ([indexes containsIndex:0]) {
        [self willChangeValueForKey:@"aGlyph"];
    }
    
    [self willChangeValueForKey:@"averageOnGlyphs"];
    [self willChangeValueForKey:@"averageOnOtherGlyphs"];
    [self willChangeValueForKey:@"glyphsCommonSize"];
    _averageOnGlyphs=_averageOnOtherGlyphs=NAN;
    _glyphsCommonSize=NSMakeSize(NAN, NAN);
    
    [self.glyphs replaceObjectsAtIndexes:indexes withObjects:array];
    
    [self didChangeValueForKey:@"glyphsCommonSize"];
    [self didChangeValueForKey:@"averageOnOtherGlyphs"];
    [self didChangeValueForKey:@"averageOnGlyphs"];

    if ([indexes containsIndex:0]) {
        [self didChangeValueForKey:@"aGlyph"];
    }
    [self didChangeValueForKey:@"count"];
    [self didChangeValueForKey:@"description"];
}

- (void)replaceObjectInGlyphsAtIndex:(NSUInteger)index withObject:(NNGlyph *)object
{
    [self willChangeValueForKey:@"count"];
    [self willChangeValueForKey:@"description"];
    if (index==0) {
        [self willChangeValueForKey:@"aGlyph"];
    }
    
    [self willChangeValueForKey:@"averageOnGlyphs"];
    [self willChangeValueForKey:@"averageOnOtherGlyphs"];
    [self willChangeValueForKey:@"glyphsCommonSize"];
    _averageOnGlyphs=_averageOnOtherGlyphs=NAN;
    _glyphsCommonSize=NSMakeSize(NAN, NAN);
    
    [self.glyphs replaceObjectAtIndex:index withObject:object];
    
    [self didChangeValueForKey:@"glyphsCommonSize"];
    [self didChangeValueForKey:@"averageOnOtherGlyphs"];
    [self didChangeValueForKey:@"averageOnGlyphs"];

    if (index==0) {
        [self didChangeValueForKey:@"aGlyph"];
    }
    [self didChangeValueForKey:@"count"];
    [self didChangeValueForKey:@"description"];
}

- (void)ensureGlyphsHaveTheSameSize
{
    // loop in the glyphs and compute max size
    NSSize sz=NSMakeSize(0., 0.);
    for (NNGlyph *g in self.glyphs) {
        if (g.rect.size.width>sz.width) sz.width=g.rect.size.width;
        if (g.rect.size.height>sz.height) sz.height=g.rect.size.height;
    }
    
    // ensure they have that size
    for (NNGlyph *g in self.glyphs) {
        if (g.image.size.width!=sz.width || g.image.size.height!=sz.height)
            [g discardInputVector];
        
        [g expandImageToSize:sz];
    }
    
    [self willChangeValueForKey:@"glyphsCommonSize"];
    _glyphsCommonSize=sz;
    [self didChangeValueForKey:@"glyphsCommonSize"];
}

- (NNGlyph *)aGlyph
{
    return [self.glyphs objectAtIndex:0];
}

- (NSUInteger)count
{
    return self.glyphs.count;
}

- (NSString *)description
{
    if (self.network.examplesGiven>0) {
        return [NSString stringWithFormat:@"%lu glyphs, trained with %lu examples", self.glyphs.count, self.network.examplesGiven,nil];
    } else {
        return [NSString stringWithFormat:@"%lu glyphs, not trained yet", self.glyphs.count, nil];
    }
}

@end
