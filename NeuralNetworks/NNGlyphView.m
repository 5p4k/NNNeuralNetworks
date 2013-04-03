//
//  NNGlyphView.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 20/05/12.
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

#import "NNGlyphView.h"

@implementation NNGlyphView
@synthesize glyph=_glyph,selected=_selected;

- (void)dealloc
{
    self.glyph=nil;
    
    [super dealloc];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self setNeedsDisplay:YES];
}

- (NNGlyph *)glyph
{
    return _glyph;
}

- (BOOL)isSelected
{
    return _selected;
}

- (void)setSelected:(BOOL)selected
{
    if (_selected!=selected) {
        _selected=selected;
        [self setNeedsDisplay:YES];
    }
        
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (!drawingImage) return;
    
    // draw imagerep
    NSSize selfSize=self.frame.size;
    selfSize.width-=20.;
    selfSize.height-=20.;
    NSRect dest=NSMakeRect(0., 0., drawingImage.size.width, drawingImage.size.height);
    
    if (dest.size.width>selfSize.width || dest.size.height>selfSize.height) {
        
        CGFloat selfRatio=selfSize.width/selfSize.height;
        CGFloat imgRatio=dest.size.width/dest.size.height;
        
        if (selfRatio>imgRatio) {
            dest.size.height=selfSize.height;
            dest.size.width=selfSize.height*imgRatio;
        } else {
            dest.size.width=selfSize.width;
            dest.size.height=selfSize.width/imgRatio;
        }
        
    }
    
    dest.origin=NSMakePoint(10.+(selfSize.width-dest.size.width)*.5,
                            10.+(selfSize.height-dest.size.height)*.5);

    [NSGraphicsContext saveGraphicsState];
    
    // use rep as clipping path
    if (self.selected) {
        NSShadow *shd=[[NSShadow alloc] init];
        shd.shadowColor=[NSColor whiteColor];
        shd.shadowBlurRadius=10.;
        shd.shadowOffset=NSMakeSize(0., 0.);
        [shd set];
        [shd release];
        
        // predraw image to have a stronger shadow
        [drawingImage drawInRect:dest
                        fromRect:NSMakeRect(0., 0., drawingImage.size.width, drawingImage.size.height)
                       operation:NSCompositeSourceOver
                        fraction:1.];
    }
    
    [drawingImage drawInRect:dest
                    fromRect:NSMakeRect(0., 0., drawingImage.size.width, drawingImage.size.height)
                   operation:NSCompositeSourceOver
                    fraction:1.];
    
    [NSGraphicsContext restoreGraphicsState];
    
}

- (void)setGlyph:(NNGlyph *)glyph
{
    if (_glyph==glyph) return;
    
    [_glyph release];
    _glyph=[glyph retain];
    [drawingImage release];
    drawingImage=nil;
    
    if (glyph.imageRep) {
        
        drawingImage=[[NSImage alloc] initWithSize:glyph.imageRep.size];
        [drawingImage lockFocus];
        
        NSGradient *fill=[[NSGradient alloc] initWithStartingColor:[NSColor controlTextColor]
                                                       endingColor:[[NSColor disabledControlTextColor] shadowWithLevel:.2]];
        
        NSRect wholeImg=NSMakeRect(0., 0., glyph.imageRep.size.width, glyph.imageRep.size.height);
        
        CGContextClipToMask([[NSGraphicsContext currentContext] graphicsPort],
                            wholeImg,
                            glyph.imageRep.CGImage);
        
        [fill drawInRect:wholeImg
                   angle:90.];
        
        [fill release];
        
        [drawingImage unlockFocus];
        
    }
    
    [self setNeedsDisplay:YES];
}

@end
