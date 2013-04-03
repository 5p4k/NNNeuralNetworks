//
//  NNHorizontalScrollView.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 17/05/12.
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

#import "NNHorizontalScrollView.h"

@implementation NNHorizontalScrollView

- (void)scrollWheel:(NSEvent *)theEvent
{
    // send to super the event with only the horizontal component and eventually pass to next responder
    // the vertical movement
    
    if (fabs(theEvent.scrollingDeltaX)!=0. && fabs(theEvent.scrollingDeltaY)==0.) {
        
        // simply forward
        [super scrollWheel:theEvent];
        
    } else if (fabs(theEvent.scrollingDeltaX)==0. && fabs(theEvent.scrollingDeltaY)!=0.) {
        
        // simply forward
        [self.nextResponder scrollWheel:theEvent];
        
    } else {
        
        // decompose
        CGEventSourceRef source=CGEventCreateSourceFromEvent(theEvent.CGEvent);
        CGEventRef eventX=CGEventCreate(source);
        CGEventRef eventY=CGEventCreate(source);
        
        CGEventSetType(eventX, kCGEventScrollWheel);
        CGEventSetType(eventY, kCGEventScrollWheel);
        
        CGEventSetIntegerValueField(eventY,
                                    kCGScrollWheelEventFixedPtDeltaAxis1,
                                    (int64_t)(theEvent.scrollingDeltaY*(double)0x10000));
        CGEventSetIntegerValueField(eventX,
                                    kCGScrollWheelEventFixedPtDeltaAxis2,
                                    (int64_t)(theEvent.scrollingDeltaX*(double)0x10000));
        
        CGEventSetIntegerValueField(eventX, kCGScrollWheelEventIsContinuous, 1);
        CGEventSetIntegerValueField(eventX, kCGScrollWheelEventIsContinuous, 1);
        
        // generate the relative events
        NSEvent *x=[NSEvent eventWithCGEvent:eventX];
        NSEvent *y=[NSEvent eventWithCGEvent:eventY];
        
        [super scrollWheel:x];
        [self.nextResponder scrollWheel:y];
        
        CFRelease(eventX);
        CFRelease(eventY);
        CFRelease(source);
        
        
    }
    
}

@end
