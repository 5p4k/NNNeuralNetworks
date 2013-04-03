//
//  NNDocument.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 28/05/12.
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

#import "NNDocument.h"
#import "NNNetworkWindowController.h"

@implementation NNDocument
@synthesize glyphsClasses=_glyphsClasses;

- (id)init
{
    self = [super init];
    if (self) {
        _glyphsClasses=[[NSMutableArray alloc] initWithCapacity:50];
    }
    return self;
}

- (void)dealloc
{
    [_glyphsClasses release];
    
    [super dealloc];
}

- (BOOL)hasAnyClass
{
    return self.glyphsClasses.count>0;
}

- (void)insertObject:(NNGlyphsClass *)object inGlyphsClassesAtIndex:(NSUInteger)index
{
    [self willChangeValueForKey:@"hasAnyClass"];
    [self.glyphsClasses insertObject:object atIndex:index];
    [self didChangeValueForKey:@"hasAnyClass"];
}

- (void)removeObjectFromGlyphsClassesAtIndex:(NSUInteger)index
{
    [self willChangeValueForKey:@"hasAnyClass"];
    [self.glyphsClasses removeObjectAtIndex:index];
    [self didChangeValueForKey:@"hasAnyClass"];
}

- (void)makeWindowControllers
{
    // make the window controller
    NNNetworkWindowController *mwc=[[NNNetworkWindowController alloc] initWithWindowNibName:@"NNNetworkWindowController"];
    [self addWindowController:mwc];
    [mwc release];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    return [NSKeyedArchiver archivedDataWithRootObject:self.glyphsClasses];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    [_glyphsClasses release];
    _glyphsClasses=[[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];
    
    return YES;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
