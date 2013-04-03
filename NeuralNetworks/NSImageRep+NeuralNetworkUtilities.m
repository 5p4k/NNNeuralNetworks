//
//  NSImageRep+NeuralNetworkUtilities.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 23/05/12.
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

#import "NSImageRep+NeuralNetworkUtilities.h"

@implementation NSImageRep (NeuralNetworkUtilities)
- (NSBitmapImageRep *)imageRepWithNNInputOfSize:(NSSize)sz clamp:(BOOL)clamp
{
    // compute the right size
    NSRect sourceRect=NSMakeRect(0., 0., sz.width*self.size.height/sz.height, self.size.height);
    NSRect destRect=NSMakeRect(0., 0., sz.width, sz.height);
    if (sourceRect.size.width>self.size.width) {
        sourceRect.size.width=self.size.width;
        destRect.size.width=self.size.width*destRect.size.height/sourceRect.size.height;
    }
    destRect.origin.x=.5*(sz.width-destRect.size.width);
    
    // prepare a rep that uses the right data format
    NSBitmapImageRep *rep=[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                  pixelsWide:(NSInteger)sz.width
                                                                  pixelsHigh:(NSInteger)sz.height
                                                               bitsPerSample:sizeof(float)*8
                                                             samplesPerPixel:1
                                                                    hasAlpha:NO
                                                                    isPlanar:NO
                                                              colorSpaceName:NSCalibratedWhiteColorSpace
                                                                bitmapFormat:NSFloatingPointSamplesBitmapFormat
                                                                 bytesPerRow:sizeof(float)*(NSUInteger)sz.width
                                                                bitsPerPixel:8*sizeof(float)];
    
    // create a gc and draw into it
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];
    
    [self drawInRect:destRect fromRect:sourceRect operation:NSCompositeCopy fraction:1. respectFlipped:YES hints:nil];
    
    [NSGraphicsContext restoreGraphicsState];
    
    // return directly the nsimagerep. float array in in rep.bitmapdata
    if (clamp) {
        int inputSz=(int)(sz.width*sz.height);
        cblas_sscal(inputSz, 2., (float *)rep.bitmapData, 1);
        for (NSUInteger i=0; i<inputSz; ++i)
            ((float *)rep.bitmapData)[i]-=1.;
    }
    
    return [rep autorelease];
}
@end
