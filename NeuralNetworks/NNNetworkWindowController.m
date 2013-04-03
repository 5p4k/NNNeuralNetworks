//
//  NNNetworkWindowController.m
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

#import "NNNetworkWindowController.h"
#import "NNNewGlyphsSheetController.h"
#import "NNGlyph.h"
#import "NNGlyphsClass.h"
#import "NNTrainingSheetController.h"
#import "NNFeedForwardNetwork.h"
#import "NNDocument.h"

@implementation NNNetworkWindowController
@synthesize glyphsClassesController=_glyphsClassesController,selectedClass=_selectedClass,selectedCells=_selectedCells;

- (void)scanPage:(id)sender
{
    if (![self.document hasAnyClass]) return;
    
    NSOpenPanel *openPanel=[NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"jpg",@"png", nil]];
    [openPanel setResolvesAliases:YES];
    [openPanel setCanSelectHiddenExtension:YES];
    [openPanel setTitle:@"Open image."];
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result==NSOKButton) {
            
            NSImage *img=[[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:openPanel.URL]];
            
            NNNewGlyphsSheetController *ngs=[[NNNewGlyphsSheetController trainerSheetControllerWithImage:img] retain];
            
            [ngs loadWindow];
            [ngs enterScanningMode];
            ngs.glyphsClasses=[self.document glyphsClasses];
            
            [openPanel close];
            [[NSApplication sharedApplication] beginSheet:ngs.window
                                           modalForWindow:self.window
                                            modalDelegate:nil
                                           didEndSelector:nil
                                              contextInfo:NULL];
            
            [NSApp runModalForWindow:ngs.window];
            [NSApp endSheet:ngs.window];
            [ngs.window orderOut:self];
            [ngs release];
            [img release];
        }
    }];

}

- (void)windowWillClose:(NSNotification *)notification
{
    [self setSelectedCells:[NSMutableIndexSet indexSet]];
}

- (void)trainNetwork:(id)sender
{
    if (![self.document hasAnyClass]) return;
    
    NNTrainingSheetController *tsc=[[NNTrainingSheetController alloc] initWithWindowNibName:@"NNTrainingSheetController"];
    [tsc setGlyphsClasses:[self.document glyphsClasses]];
    [[NSApplication sharedApplication] beginSheet:tsc.window
                                   modalForWindow:self.window
                                    modalDelegate:nil
                                   didEndSelector:nil
                                      contextInfo:NULL];
    [NSApp runModalForWindow:tsc.window];
    [NSApp endSheet:tsc.window];
    [tsc.window orderOut:self];    
    [tsc release];
    [self.document updateChangeCount:NSSaveOperation];

}

- (void)removeClasses:(id)sender
{
    if (self.selectedCells.count>0) {
        NSAlert *alert=[NSAlert alertWithMessageText:@"Remove glyphs classes"
                                       defaultButton:@"No"
                                     alternateButton:@"Yes"
                                         otherButton:nil
                           informativeTextWithFormat:@"Are you sure you want to remove %lu items?",self.selectedCells.count,nil];
        if ([alert runModal]==0) {
            // delete!
            [self.glyphsClassesController removeObjectsAtArrangedObjectIndexes:self.selectedCells];
            [self.document updateChangeCount:NSSaveOperation];
        }
    }
}

- (void)addNewGlyphs:(id)sender
{
    NSOpenPanel *openPanel=[NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"jpg",@"png", nil]];
    [openPanel setResolvesAliases:YES];
    [openPanel setCanSelectHiddenExtension:YES];
    [openPanel setTitle:@"Open image."];
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result==NSOKButton) {
            
            NSImage *img=[[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:openPanel.URL]];
            
            NNNewGlyphsSheetController *ngs=[[NNNewGlyphsSheetController trainerSheetControllerWithImage:img] retain];
            
            [openPanel close];
            
            [[NSApplication sharedApplication] beginSheet:ngs.window
                                           modalForWindow:self.window
                                            modalDelegate:nil
                                           didEndSelector:nil
                                              contextInfo:NULL];
            [NSApp runModalForWindow:ngs.window];
            [NSApp endSheet:ngs.window];
            [ngs.window orderOut:self];
            
            // now get the glyphs!
            [self.glyphsClassesController addObjects:ngs.glyphsClasses];
            [self.document updateChangeCount:NSSaveOperation];
            
            [ngs release];
            [img release];
        }
    }];
}

- (void)setSelectedCells:(NSMutableIndexSet *)selectedCells
{
    [self willChangeValueForKey:@"selectedClass"];
    [_selectedCells release];
    _selectedCells=[selectedCells retain];
    [self didChangeValueForKey:@"selectedClass"];
    
    [self whoIsThis:self];
}

- (void)whoIsThis:(id)sender
{
    if (self.selectedClass) {
        NNGlyph *g=self.selectedClass.aGlyph;
        
        CGFloat resultOnSelf=NAN;
        
        NNGlyph *cp=[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:g]];
        
        NNGlyphsClass *bestClass=nil;
        CGFloat bestResult=-INFINITY;
        
        CGFloat glyphRatio=g.rect.size.width/g.rect.size.height;
        for (NNGlyphsClass *cls in [self.document glyphsClasses]) {
            
            CGFloat expRatio=cls.glyphsCommonSize.width/cls.glyphsCommonSize.height;
            CGFloat ratio=expRatio/glyphRatio;
            
            if (ratio<0.75 || ratio>1.21) continue;
            
            [cp expandImageToSize:cls.glyphsCommonSize];
            [cp computeInputVectorForSize:NSMakeSize(M_NETWORK_INPUT_X, M_NETWORK_INPUT_Y)];
            
            CGFloat result=[cls.network resultForInput:cp.inputVector];
            result=(result-cls.averageOnOtherGlyphs)/(cls.averageOnGlyphs-cls.averageOnOtherGlyphs);
            
            if (self.selectedClass==cls)
                resultOnSelf=result;
            
            if (result>bestResult) {
                bestClass=cls;
                bestResult=result;
            }
            
        }
        
        [cp expandImageToSize:self.selectedClass.glyphsCommonSize];
        [cp computeInputVectorForSize:NSMakeSize(M_NETWORK_INPUT_X, M_NETWORK_INPUT_Y)];
        CGFloat result=[self.selectedClass.network resultForInput:cp.inputVector];
        result=(result-self.selectedClass.averageOnOtherGlyphs)/(self.selectedClass.averageOnGlyphs-self.selectedClass.averageOnOtherGlyphs);
        
        CGFloat ratio=g.rect.size.width/g.rect.size.height;
        CGFloat r1=bestClass.glyphsCommonSize.width/bestClass.glyphsCommonSize.height;
        CGFloat r2=self.selectedClass.glyphsCommonSize.width/self.selectedClass.glyphsCommonSize.height;
        r1/=ratio;
        r2/=ratio;
        
        if (bestClass==self.selectedClass) return;
        NSLog(@"%@ -> %@, con %f (vs %f), ratio %f (vs %f)",self.selectedClass.label, bestClass.label,bestResult,result,r1,r2);
    }
}

- (NNGlyphsClass *)selectedClass
{
    if (self.selectedCells.count==0) return nil;
    return [self.glyphsClassesController.arrangedObjects objectAtIndex:self.selectedCells.firstIndex];
}

- (NSMutableIndexSet *)selectedCells
{
    return _selectedCells;
}

- (void)awakeFromNib
{
    // fix Cocoa layout
    NSView *contentView=self.window.contentView;
    [contentView removeConstraints:contentView.constraints];
    NSView *childView=[contentView.subviews objectAtIndex:0];
    
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[childView]-(0)-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:NSDictionaryOfVariableBindings(childView)]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[childView]-(0)-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:NSDictionaryOfVariableBindings(childView)]];
    [contentView setNeedsLayout:YES];
}

@end
