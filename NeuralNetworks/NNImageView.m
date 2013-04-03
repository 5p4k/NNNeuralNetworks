//
//  NNImageView.m
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

#import "NNImageView.h"
#import <Quartz/Quartz.h>

@implementation NNImageView
@synthesize image=_image,delegate=_delegate,imageOrigin=_imageOrigin,scaleFactor=_scaleFactor;

- (void)dealloc
{
    self.image=nil;
    
    [super dealloc];
}

- (CGFloat)scaleFactor
{
    return _scaleFactor;
}

- (CGPoint)imageOrigin
{
    return _imageOrigin;
}

- (NSImage *)image
{
    return _image;
}

- (void)setScaleFactor:(CGFloat)scaleFactor
{
    if (scaleFactor==_scaleFactor) return;
    _scaleFactor=scaleFactor;
    _scaleFactor=fmin(fmax(self.image.size.width/(-8.+self.frame.size.width), self.image.size.height/(-8.+self.frame.size.height)), _scaleFactor);
    [self setNeedsDisplay:YES];
}

- (void)setImageOrigin:(CGPoint)imageOrigin
{
    if (CGPointEqualToPoint(imageOrigin, self.imageOrigin)) return;
    _imageOrigin=imageOrigin;
    _imageOrigin.x=fmax(fmin(self.image.size.width, _imageOrigin.x), 0.);
    _imageOrigin.y=fmax(fmin(self.image.size.height, _imageOrigin.y), 0.);
    [self setNeedsDisplay:YES];
}

- (void)setImage:(NSImage *)image
{
    if (image!=_image) {
        [_image release];
        _image=[image retain];
        
        // reset window
        _imageOrigin=CGPointMake(.5*image.size.width, .5*image.size.height);
        _scaleFactor=fmax(self.image.size.width/(-8.+self.frame.size.width), self.image.size.height/(-8.+self.frame.size.height));
        
        [self setNeedsDisplay:YES];
    }    
}

+ (id)defaultAnimationForKey:(NSString *)key
{
    if ([key isEqualToString:@"scaleFactor"] || [key isEqualToString:@"imageOrigin"]) {        
        return [CABasicAnimation animationWithKeyPath:key];
    }
    
    return [NSView defaultAnimationForKey:key];
}

- (void)fitZoom:(id)sender
{
    [(NNImageView *)[self animator] setScaleFactor:fmax(self.image.size.width/(-8.+self.frame.size.width), self.image.size.height/(-8.+self.frame.size.height))];
    [(NNImageView *)[self animator] setImageOrigin:CGPointMake(.5*self.image.size.width, .5*self.image.size.height)];
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef ctx=(CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, self.frame.size.width*.5, self.frame.size.height*.5);
    CGContextScaleCTM(ctx, 1./self.scaleFactor, 1./self.scaleFactor);
    CGContextTranslateCTM(ctx, -self.imageOrigin.x, -self.imageOrigin.y);
    
    CGContextSaveGState(ctx);
    CGContextSetShadow(ctx, CGSizeZero, 5.);
    
    [self.image drawAtPoint:NSMakePoint(0., 0.)
                   fromRect:NSMakeRect(0., 0., self.image.size.width, self.image.size.height)
                  operation:NSCompositeCopy
                   fraction:1.];
    
    CGContextRestoreGState(ctx);

    if (!self.delegate || ![self.delegate respondsToSelector:@selector(imageViewWantsToDrawExtraContent:)]) {
        CGContextRestoreGState(ctx);
        return;
    }

    CGContextTranslateCTM(ctx, 0., self.image.size.height);
    CGContextScaleCTM(ctx, 1., -1.);
    
    [self.delegate imageViewWantsToDrawExtraContent:self];
    
    CGContextRestoreGState(ctx);
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    if (!self.image) return;

    _imageOrigin=CGPointMake(self.imageOrigin.x-.5*theEvent.scrollingDeltaX*self.scaleFactor, self.imageOrigin.y+.5*theEvent.scrollingDeltaY*self.scaleFactor);
    
    _imageOrigin.x=fmax(fmin(self.image.size.width, _imageOrigin.x), 0.);
    _imageOrigin.y=fmax(fmin(self.image.size.height, _imageOrigin.y), 0.);
    
    [self setNeedsDisplay:YES];
}
- (void)setFrameSize:(NSSize)newSize
{
    CGSize oldSize=self.frame.size;
    
    [super setFrameSize:newSize];
    
    // check for scale factor
    CGFloat wantedScaleFactor=fmax(self.image.size.width/(-8.+oldSize.width), self.image.size.height/(-8.+oldSize.height));
    if (_scaleFactor==wantedScaleFactor) {
        _scaleFactor=fmax(self.image.size.width/(-8.+self.frame.size.width), self.image.size.height/(-8.+self.frame.size.height));
    }
}

- (void)magnifyWithEvent:(NSEvent *)event
{
    if (!self.image) return;
    _scaleFactor*=1.-event.magnification;

    _scaleFactor=fmin(fmax(self.image.size.width/(-8.+self.frame.size.width), self.image.size.height/(-8.+self.frame.size.height)), _scaleFactor);
    [self setNeedsDisplay:YES];
}

@end
