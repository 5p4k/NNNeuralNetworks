//
//  NNErrorGraphView.m
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

#import "NNErrorGraphView.h"

@implementation NNErrorGraphView
@synthesize values=_values,markIndex=_markIndex;

- (NSInteger)markIndex
{
    return _markIndex;
}

- (void)setMarkIndex:(NSInteger)markIndex
{
    if (markIndex==_markIndex) return;
    
    _markIndex=markIndex;
    [self setNeedsDisplay:YES];
}

- (NSArray *)values
{
    return _values;
}

- (void)setValues:(NSArray *)values
{
    [_values release];
    _values=[values retain];
    [self setNeedsDisplay:YES];
}

- (void)dealloc
{
    self.values=nil;
    
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    [NSBezierPath setDefaultLineWidth:1.5];
    NSArray *copy=[self.values copy];

    // Drawing code here.
    if (!copy || copy.count<2) {
        
        NSDictionary *fontProperties=[NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSFont systemFontOfSize:16.], NSFontAttributeName,
                                      [NSColor disabledControlTextColor], NSForegroundColorAttributeName,
                                      nil];
        NSString *str=(copy ? @"(not trained yet)": @"(no data)");
        NSSize sz=[str sizeWithAttributes:fontProperties];
        NSPoint pt=NSMakePoint(.5*(self.frame.size.width-sz.width), .5*(self.frame.size.height-sz.height));
        [str drawAtPoint:pt withAttributes:fontProperties];
    } else if (copy.count>=2) {
        // get the two labels...
        CGFloat values1[copy.count];
        CGFloat values2[copy.count];
        
        CGFloat min1=INFINITY, max1=-INFINITY;
        CGFloat min2=INFINITY, max2=-INFINITY;

        for (NSUInteger i=0; i<copy.count; ++i) {
            NSPoint pt=[[copy objectAtIndex:i] pointValue];
            values1[i]=pt.x;
            values2[i]=pt.y;
            if (values1[i]<min1) min1=values1[i];
            if (values1[i]>max1) max1=values1[i];
            if (values2[i]<min2) min2=values2[i];
            if (values2[i]>max2) max2=values2[i];
        }
        
        /*NSString *lblTop=[NSString stringWithFormat:@"%1.2f",min,nil];
        NSString *lblBottom=[NSString stringWithFormat:@"%1.2f",max,nil];
        
        // define font properties and draw
        NSDictionary *fontProperties=[NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSFont systemFontOfSize:10.], NSFontAttributeName,
                                      [NSColor controlTextColor], NSForegroundColorAttributeName,
                                      nil];
        
        NSSize szTop=[lblTop sizeWithAttributes:fontProperties];
        NSSize szBottom=[lblBottom sizeWithAttributes:fontProperties];
        
        CGFloat w=fmax(szTop.width, szBottom.width);

        [lblBottom drawAtPoint:NSMakePoint(w-szBottom.width, 0.) withAttributes:fontProperties];
        [lblTop drawAtPoint:NSMakePoint(w-szTop.width,self.frame.size.height-szTop.height)
             withAttributes:fontProperties];*/
        CGFloat w=2.; NSSize szBottom=NSMakeSize(2., 2.); NSSize szTop=NSMakeSize(2., 2.);
        
        // now define graph rect and draw inside!
        NSRect graph=NSMakeRect(w+4.,
                                szBottom.height*.5,
                                self.frame.size.width-w-8.,
                                self.frame.size.height-(szBottom.height+szTop.height)*.5);
        
        // first of all axes.
        [[NSColor blackColor] setStroke];
        [NSBezierPath strokeLineFromPoint:graph.origin toPoint:NSMakePoint(graph.origin.x, graph.origin.y+graph.size.height)];
        [NSBezierPath strokeLineFromPoint:graph.origin toPoint:NSMakePoint(graph.origin.x+graph.size.width, graph.origin.y)];
        
        // now properly draw lines
        CGFloat step=graph.size.width/(double)copy.count;
        CGContextRef ctx=[NSGraphicsContext currentContext].graphicsPort;
        
        for (NSUInteger i=0; i<copy.count; ++i) {
            values1[i]=graph.size.height*(values1[i]-min1)/(max1-min1);
            values2[i]=graph.size.height*(values2[i]-min2)/(max2-min2);
        }
        
        NSColor *theColor1=[NSColor selectedMenuItemColor]; // .18 .3 .5
        NSColor *theColor2=[NSColor selectedMenuItemTextColor];
        
        NSPoint lastPt1=NSMakePoint(graph.origin.x, graph.origin.y+values1[0]);
        NSPoint lastPt2=NSMakePoint(graph.origin.x, graph.origin.y+values2[0]);
        
        if (step>3. || self.markIndex==0) {
            CGContextFillEllipseInRect(ctx, CGRectMake(lastPt1.x-2., lastPt1.y-2., 4., 4.));
            CGContextFillEllipseInRect(ctx, CGRectMake(lastPt2.x-2., lastPt2.y-2., 4., 4.));
        }
        if (self.markIndex==0) {
            [[NSColor colorWithCalibratedRed:.9 green:0. blue:0. alpha:1.] setStroke];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(lastPt1.x, graph.origin.y)
                                      toPoint:NSMakePoint(lastPt1.x, graph.origin.y+graph.size.height)];
        }

        
        for (NSUInteger i=1; i<copy.count; ++i) {
            NSPoint newPt1=NSMakePoint(lastPt1.x+step, graph.origin.y+values1[i]);
            NSPoint newPt2=NSMakePoint(lastPt2.x+step, graph.origin.y+values2[i]);
            
            [theColor1 setStroke];
            [NSBezierPath strokeLineFromPoint:lastPt1 toPoint:newPt1];
            [theColor2 setStroke];
            [NSBezierPath strokeLineFromPoint:lastPt2 toPoint:newPt2];

            lastPt1=newPt1;
            lastPt2=newPt2;

            if (step>3. || self.markIndex==i) {
                [theColor1 setFill];
                CGContextFillEllipseInRect(ctx, CGRectMake(lastPt1.x-2., lastPt1.y-2., 4., 4.));
                [theColor2 setFill];
                CGContextFillEllipseInRect(ctx, CGRectMake(lastPt2.x-2., lastPt2.y-2., 4., 4.));
            }
            if (self.markIndex==i) {
                [[NSColor colorWithCalibratedRed:.9 green:0. blue:0. alpha:1.] setStroke];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(lastPt1.x, graph.origin.y)
                                          toPoint:NSMakePoint(lastPt1.x, graph.origin.y+graph.size.height)];
            }
        }        

    }
    [copy release];
    [NSGraphicsContext restoreGraphicsState];
}

@end
