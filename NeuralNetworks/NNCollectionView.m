//
//  NNCollectionView.m
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

#import "NNCollectionView.h"

@implementation NNCollectionView
@synthesize currentDraggingSession=_currentDraggingSession;

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    _currentDraggingSession=nil;
    [super draggingSession:session endedAtPoint:screenPoint operation:operation];
}

- (void)draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint
{
    _currentDraggingSession=session;
    [super draggingSession:session willBeginAtPoint:screenPoint];
}

@end
