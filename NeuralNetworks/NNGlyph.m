//
//  NNConnectedComponent.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 09/05/12.
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

#import "NNGlyph.h"

@implementation NNGlyph
@synthesize rect=_rect,imageRep=_imageRep,size=_size,barycenter=_barycenter,line=_line,image=_image,inputVector=_inputVector;

- (id)init
{
    self = [super init];
    if (self) {
        _rect=NSMakeRect(NAN, NAN, 0., 0.);
    }
    return self;
}

- (BOOL)sizeGreaterThanFractionOfRect:(CGFloat)fraction
{
    return self.size>(fraction*self.rect.size.width*self.rect.size.height);
}

- (NSComparisonResult)compare:(NNGlyph *)c
{
    if (self.rect.origin.x<c.rect.origin.x) return NSOrderedAscending;
    if (self.rect.origin.x>c.rect.origin.x) return NSOrderedDescending;
    
    if (self.rect.size.width<c.rect.size.width) return NSOrderedAscending;
    if (self.rect.size.width>c.rect.size.width) return NSOrderedDescending;
    
    if (self.rect.origin.y>c.rect.origin.y) return NSOrderedAscending;
    if (self.rect.origin.y<c.rect.origin.y) return NSOrderedDescending;
    
    if (self.rect.size.height>c.rect.size.height) return NSOrderedAscending;
    if (self.rect.size.height<c.rect.size.height) return NSOrderedDescending;
    
    if (self.size>c.size) return NSOrderedAscending;
    if (self.size<c.size) return NSOrderedDescending;
    
    return NSOrderedSame;

}

- (NSArray *)splitAtX:(NSUInteger)x
{
    if (x>=self.rect.size.width || x==0)
        return nil;
    
    NNGlyph *a=[[NNGlyph alloc] init];
    NNGlyph *b=[[NNGlyph alloc] init];
    
    [a expandToIncludeX:self.rect.origin.x y:self.rect.origin.y];
    [b expandToIncludeX:self.rect.origin.x+x+1 y:self.rect.origin.y];
    [a expandToIncludeX:self.rect.origin.x+x y:self.rect.origin.y+self.rect.size.height];
    [b expandToIncludeX:self.rect.origin.x+self.rect.size.width y:self.rect.origin.y+self.rect.size.height];
    
    a.line=b.line=self.line;
    
    if (self.imageRep) {
        
        [a setupImage];
        [b setupImage];
        
        for (NSUInteger u=0; u<self.rect.size.width; ++u)
            for (NSUInteger v=0; v<self.rect.size.height; ++v)
                if ([self.imageRep colorAtX:u y:v].whiteComponent>=.5)
                    [(u<=x ? a : b) addPointX:u+(NSUInteger)self.rect.origin.x y:v+(NSUInteger)self.rect.origin.y];
        
    }
    
    return [NSArray arrayWithObjects:[a autorelease],[b autorelease], nil];
}

- (void)addPointX:(NSUInteger)x y:(NSUInteger)y
{
    if (!self.imageRep) return;
    if (!CGRectContainsPoint(self.rect, CGPointMake((CGFloat)x, (CGFloat)y))) return;
    
    x-=(NSInteger)self.rect.origin.x;
    y-=(NSInteger)self.rect.origin.y;
    
    
    if (![self valueOfPointX:x y:y]) {
        _size++;
        [self.imageRep setColor:[NSColor colorWithCalibratedWhite:1. alpha:1.] atX:x y:y];
        baryX+=x;
        baryY+=y;
        
        yNorms[x]++;
        
        _barycenter=NSMakePoint(self.rect.origin.x+((CGFloat)baryX)/(CGFloat)self.size, self.rect.origin.y+((CGFloat)baryY)/(CGFloat)self.size);
    }
}

- (void)removePointX:(NSUInteger)x y:(NSUInteger)y
{
    if (!self.imageRep) return;
    if (!CGRectContainsPoint(self.rect, CGPointMake((CGFloat)x, (CGFloat)y))) return;
    
    x-=(NSInteger)self.rect.origin.x;
    y-=(NSInteger)self.rect.origin.y;
    
    if ([self valueOfPointX:x y:y]) {
        _size--;
        [self.imageRep setColor:[NSColor colorWithCalibratedWhite:0. alpha:1.] atX:x y:y];
        baryX-=x;
        baryY-=y;
        
        yNorms[x]--;
        
        _barycenter=NSMakePoint(self.rect.origin.x+((CGFloat)baryX)/(CGFloat)self.size, self.rect.origin.y+((CGFloat)baryY)/(CGFloat)self.size);
    }
}

- (BOOL)valueOfPointX:(NSUInteger)x y:(NSUInteger)y
{
    if (!self.imageRep) return NO;
    if (!CGRectContainsPoint(self.rect, CGPointMake((CGFloat)x, (CGFloat)y))) return NO;
    
    x-=(NSInteger)self.rect.origin.x;
    y-=(NSInteger)self.rect.origin.y;
    
    return [self.imageRep colorAtX:x y:y].whiteComponent>=.5;
}

- (void)expandToIncludeX:(NSUInteger)x y:(NSUInteger)y
{
    // trivial cases
    if (isnan(self.rect.origin.x) || isnan(self.rect.origin.y)) {
        _rect=NSMakeRect((CGFloat)x, (CGFloat)y, 1., 1.);
    } else {
        
        if (self.rect.origin.x>(CGFloat)x) {
            _rect.size.width+=self.rect.origin.x-(CGFloat)x;
            _rect.origin.x=(CGFloat)x;
        } else if (self.rect.origin.x+self.rect.size.width<1.+(CGFloat)x) {
            _rect.size.width=-self.rect.origin.x+1.+(CGFloat)x;
        }
        if (self.rect.origin.y>(CGFloat)y) {
            _rect.size.height+=self.rect.origin.y-(CGFloat)y;
            _rect.origin.y=(CGFloat)y;
        } else if (self.rect.origin.y+self.rect.size.height<1.+(CGFloat)y) {
            _rect.size.height=-self.rect.origin.y+1.+(CGFloat)y;
        }
        
    }
}

+ (NNGlyph *)connectedComponentByMerging:(NNGlyph *)a with:(NNGlyph *)b
{
    NNGlyph *c=[[NNGlyph alloc] init];
    
    c->_rect=NSUnionRect(a.rect, b.rect);
    
    if (a.imageRep || b.imageRep) [c setupImage];
    
    NSColor *white=[NSColor colorWithCalibratedWhite:1. alpha:1.];
    
    if (a.imageRep) {
        
        NSUInteger offsetX=(NSUInteger)(a.rect.origin.x-c.rect.origin.x);
        NSUInteger offsetY=(NSUInteger)(a.rect.origin.y-c.rect.origin.y);
        
        for (NSUInteger x=0; x<a.rect.size.width; ++x) {
            c->yNorms[offsetX+x]=a->yNorms[x];
            for (NSUInteger y=0; y<a.rect.size.height; ++y)
                if ([a.imageRep colorAtX:x y:y].whiteComponent>=.5)
                    [c.imageRep setColor:white atX:x+offsetX y:y+offsetY];
        }
        
        c->baryX=a->baryX+a.size*offsetX;
        c->baryY=a->baryY+a.size*offsetY;
        c->_size=a.size;
    }
    
    if (b.imageRep) {
        
        NSUInteger offsetX=(NSUInteger)(b.rect.origin.x-c.rect.origin.x);
        NSUInteger offsetY=(NSUInteger)(b.rect.origin.y-c.rect.origin.y);
        
        for (NSUInteger x=0; x<b.rect.size.width; ++x) {
            c->yNorms[offsetX+x]+=b->yNorms[x];
            for (NSUInteger y=0; y<b.rect.size.height; ++y)
                if ([b.imageRep colorAtX:x y:y].whiteComponent>=.5)
                    [c.imageRep setColor:white atX:x+offsetX y:y+offsetY];
        }
        
        c->baryX+=b->baryX+b.size*offsetX;
        c->baryY+=b->baryY+b.size*offsetY;
        c->_size+=b.size;
    }
    
    if (a.imageRep || b.imageRep)
        c->_barycenter=NSMakePoint(c.rect.origin.x+((CGFloat)c->baryX)/(CGFloat)c.size,
                                   c.rect.origin.y+((CGFloat)c->baryY)/(CGFloat)c.size);
    
    if (NSEqualRanges(a.line.rangeValue, b.line.rangeValue)) c.line=a.line;

    return [c autorelease];
}

- (NSInteger)findHorizontalMinimum:(NSUInteger *)x inRange:(NSRange)rg greaterThan:(NSUInteger)min
{
    if (!self.imageRep) return NSNotFound;
    
    NSInteger minNorm=NSNotFound;
    NSInteger minLocation=NSNotFound;
    
    for (NSUInteger u=0; u<rg.length; ++u) {
        if (yNorms[rg.location+u]<min) continue;
        
        if (yNorms[rg.location+u]<minNorm || minLocation==NSNotFound) {
            minNorm=yNorms[rg.location+u];
            minLocation=rg.location+u;
        }
    }
    
    if (x) (*x)=minLocation;
    return minNorm;
}

- (void)computeInputVectorForSize:(NSSize)sz
{
    if (!self.image) return;
    
    if (_inputVector) free(_inputVector);
    
    NSBitmapImageRep *rep=[[self.image imageRepWithNNInputOfSize:sz clamp:YES] retain];
    
    // copy memory
    NSUInteger len=sizeof(float)*(NSUInteger)(sz.width*sz.height);
    _inputVector=malloc(len);
    memcpy(_inputVector, rep.bitmapData, len);
    
    [rep release];
    
}

- (void)setupImage
{
    if (self.rect.size.width*self.rect.size.height==0) return;
    if (_imageRep) [_imageRep release];
    if (_image) [_image release];
    
    _imageRep=[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                 pixelsWide:(NSInteger)self.rect.size.width
                                                 pixelsHigh:(NSInteger)self.rect.size.height
                                              bitsPerSample:1
                                            samplesPerPixel:1
                                                   hasAlpha:NO
                                                   isPlanar:YES
                                             colorSpaceName:NSCalibratedWhiteColorSpace
                                                bytesPerRow:0
                                               bitsPerPixel:0];
    _image=[[NSImage alloc] initWithSize:_imageRep.size];
    [_image addRepresentation:_imageRep];
    
    yNorms=malloc(sizeof(NSUInteger)*(NSUInteger)self.rect.size.width);

}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self=[super init])) {
        _imageRep=[[aDecoder decodeObjectForKey:@"NNGlyph->_imageRep"] retain];
        _image=[[aDecoder decodeObjectForKey:@"NNGlyph->_image"] retain];
        _line=[[aDecoder decodeObjectForKey:@"NNGlyph->_line"] retain];
        _size=[aDecoder decodeIntegerForKey:@"NNGlyph->_size"];
        _barycenter=[aDecoder decodePointForKey:@"NNGlyph->_barycenter"];
        _rect=[aDecoder decodeRectForKey:@"NNGlyph->_rect"];
        baryY=[aDecoder decodeIntegerForKey:@"NNGlyph->_baryY"];
        baryX=[aDecoder decodeIntegerForKey:@"NNGlyph->_baryX"];
        if (self.imageRep) {
            yNorms=malloc(sizeof(NSUInteger)*(NSUInteger)self.rect.size.width);
            for (NSUInteger x=0; x<self.rect.size.width; ++x) {
                yNorms[x]=0;
                for (NSUInteger y=0; y<self.rect.size.height; ++y)
                    if ([self valueOfPointX:x y:y])
                        yNorms[x]++;
            }
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:baryX forKey:@"NNGlyph->baryX"];
    [aCoder encodeInteger:baryY forKey:@"NNGlyph->baryY"];
    [aCoder encodeRect:self.rect forKey:@"NNGlyph->_rect"];
    [aCoder encodePoint:self.barycenter forKey:@"NNGlyph->_barycenter"];
    [aCoder encodeInteger:self.size forKey:@"NNGlyph->_size"];
    [aCoder encodeObject:self.line forKey:@"NNGlyph->_line"];
    [aCoder encodeObject:self.image forKey:@"NNGlyph->_image"];
    [aCoder encodeObject:self.imageRep forKey:@"NNGlyph->_imageRep"];
}

- (void)discardInputVector
{
    if (_inputVector) free(_inputVector);
    _inputVector=NULL;
}

- (void)expandImageToSize:(NSSize)size
{
    if (!self.image) return;
    if (self.image.size.width==size.width && self.image.size.height==size.height) return;
    
    NSImage *newImage=[[NSImage alloc] initWithSize:size];
    [newImage lockFocus];
    [[NSColor blackColor] setFill];
    [NSBezierPath fillRect:NSMakeRect(0., 0., size.width, size.height)];
    [self.imageRep drawAtPoint:NSMakePoint(0., 0.)];
    [newImage unlockFocus];
    [_image release];
    _image=newImage;
}

- (void)dealloc
{
    [_imageRep release];
    [_image release];
    if (yNorms)
        free(yNorms);
    [_line release];
    
    [super dealloc];
}

@end
