//
//  NNGlyphsSetController.m
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 16/05/12.
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

#import "NNGlyphsClassView.h"
#import "NNGlyphsClass.h"

@implementation NNGlyphsClassView
@synthesize glyphsView=_glyphsView,headerView=_headerView,glyphsArrayController=_glyphsArrayController;

- (void)awakeFromNib
{
    // set properties
    [self.glyphsView setMinItemSize:NSMakeSize(50., 50.)];
    [self.glyphsView setMaxItemSize:NSMakeSize(50., 50.)];
    [self.glyphsView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    [self.glyphsView registerForDraggedTypes:[NSArray arrayWithObject:@"com.SpakSW.NeuralNetworks.Glyph"]];
}

- (void)dealloc
{
    [draggingItems release];
    
    [super dealloc];
}

- (void)setSelected:(BOOL)selected
{
    [self.headerView setSelected:selected];
}

- (BOOL)isSelected
{
    return [self.headerView isSelected];
}

- (NSString *)headerAllowedDraggingType:(NNCollectionItemBox *)hdr
{
    return @"com.SpakSW.NeuralNetworks.GlyphsClass";
}

- (void)header:(NNCollectionItemBox *)hdr receivedData:(NSData *)data
{
    NNGlyphsClass *glyphsClass=[NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    // copy everything
    [self.glyphsArrayController addObjects:glyphsClass.glyphs];
}

- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    // move!
    NSArray *items=[NSKeyedUnarchiver unarchiveObjectWithData:[[draggingInfo draggingPasteboard] dataForType:@"com.SpakSW.NeuralNetworks.Glyph"]];
    
    for (NSUInteger i=0; i<items.count; ++i) {
        [self.glyphsArrayController insertObject:[items objectAtIndex:i] atArrangedObjectIndex:index+i];
    }
    
    return YES;
}

- (void)collectionView:(NSCollectionView *)collectionView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint dragOperation:(NSDragOperation)operation
{
    if (operation==NSDragOperationMove || (operation==NSDragOperationNone && !session.animatesToStartingPositionsOnCancelOrFail)) {
        // remove from list
        [self.glyphsArrayController removeObjects:draggingItems];
    }
    
    [draggingItems release];
    draggingItems=nil;
}

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    if (![[[draggingInfo draggingPasteboard] types] containsObject:@"com.SpakSW.NeuralNetworks.Glyph"])
        return NSDragOperationNone;

    return NSDragOperationMove;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    NSMutableArray *items=[[NSMutableArray alloc] initWithCapacity:indexes.count];
    [indexes enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger idx, BOOL *stop) {
        [items addObject:[collectionView itemAtIndex:idx].representedObject];
    }];
    
    draggingItems=[[NSArray arrayWithArray:items] retain];
    
    // serialize those!
    NSString *type=@"com.SpakSW.NeuralNetworks.Glyph";
    [pasteboard declareTypes:[NSArray arrayWithObject:type] owner:nil];
    [pasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:draggingItems]
                forType:type];
    
    [items release];

     
    return YES;
}

@end
