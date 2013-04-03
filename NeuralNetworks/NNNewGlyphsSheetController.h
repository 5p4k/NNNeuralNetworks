//
//  NNNewGlyphsSheetController.h
//  NeuralNetworks
//
//  Created by Pietro Saccardi on 11/05/12.
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

#import <Cocoa/Cocoa.h>
#import "NNImageView.h"
#import "NNCollectionView.h"

@class NNMatrix,NNMyKohonenNetwork,NNGlyphsClassView;

@interface NNNewGlyphsSheetController : NSWindowController <NNImageViewDelegate, NSCollectionViewDelegate, NSWindowDelegate> {
    NSControl *stepsLabels[8];
    NSImage *pendingImage;
    NSLock *lock;
    BOOL cancelFlag;
    BOOL processRunning;
    NNGlyphsClassView *draggedItem;
}

@property (assign) IBOutlet NSProgressIndicator *spinningIndicator;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSTextView *outputField;

@property (assign) IBOutlet NSArrayController *glyphsClassesController;
@property (assign) IBOutlet NSSlider *linesThresholdSlider;
@property (assign) IBOutlet NSSlider *epsilonSlider;
@property (assign) IBOutlet NSSlider *sigmaSlider;
@property (assign) IBOutlet NSSlider *decreaseFactorSlider;
@property (assign) IBOutlet NSSlider *examplesSlider;
@property (assign) IBOutlet NSButton *resetLinesButton;
@property (assign) IBOutlet NSButton *resetNetworkButton;
@property (assign) IBOutlet NSButton *startNetworkButton;
@property (assign) IBOutlet NSButton *doneButton;
@property (assign) IBOutlet NSButton *cancelButton;
@property (assign) IBOutlet NSButton *sortButton;

@property (assign) IBOutlet NSScrollView *networkResultView;
@property (assign) IBOutlet NNCollectionView *glyphsClassesView;

@property (assign) IBOutlet NNImageView *imageView;
@property (assign) IBOutlet NSTextField *glyphsCountLabel;

@property (assign) IBOutlet NNMyKohonenNetwork *myKohonenNetwork;

@property (assign) CGFloat linesDetectionThreshold;
@property (assign) CGFloat sigmaAndEpsilonDecreaseFactor;
@property (assign) CGFloat maximumNumberOfExamples;

@property (retain) NNMatrix *imageMatrix;
@property (retain) NSArray *linesDetected;
@property (retain) NSMutableSet *glyphsFound;
@property (retain) NSMutableDictionary *glyphsByLine;

@property (retain) NSMutableArray *glyphsClasses;

@property (readonly) NSImage *image;

@property (readonly) BOOL scanningMode;

+ (NNNewGlyphsSheetController *)trainerSheetControllerWithImage:(NSImage *)img;

- (IBAction)recomputeLines:(id)sender;
- (IBAction)startImageScanningProcess:(id)sender;
- (IBAction)startNeuralNetworkProcess:(id)sender;

- (IBAction)cancelAndClose:(id)sender;
- (IBAction)done:(id)sender;

- (IBAction)sortItems:(id)sender;

- (IBAction)resetLines:(id)sender;
- (IBAction)resetNetwork:(id)sender;

- (void)enterScanningMode;
- (void)exitScanningMode;

- (void)displaySpinningIndicator;
- (void)hideSpinningIndicator;
@end
