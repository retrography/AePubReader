//
//  AREPubViewController.h
//  AePubReader
//
//  Created by Abdul Rehman (abduliam) on 04/02/2013.
//  Copyright (c) 2013 StudioNorth, Lahore. All rights reserved.
//

#import "EPubViewController.h"

@class ARePubPageContentViewController;
@class SearchResultsViewController;

@interface ARePubViewController : UIViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource> {

    @private
    UIPopoverController* chaptersPopover;
    UIPopoverController* searchResultsPopover;
    
    SearchResultsViewController* searchResViewController;
}

//IB properties
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *chapterListButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *visualSearchButton;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *decTextSizeButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *incTextSizeButton;

@property (nonatomic, retain) IBOutlet UISlider *pageSlider;
@property (nonatomic, retain) IBOutlet UILabel *currentPageLabel;


//public properties
@property (nonatomic, retain) EPub* loadedEpub;
@property (nonatomic, retain) SearchResult* currentSearchResult;

@property (nonatomic,assign) int currentTextSize;
@property (nonatomic,assign) int totalPagesCount;

@property (nonatomic,assign) BOOL searching;
@property (nonatomic,assign) BOOL epubLoaded;
@property (nonatomic,assign) BOOL paginating;


//IB methods
//From origional EPubViewController methods
- (IBAction) showChapterIndex:(id)sender;
- (IBAction) gotoNextPage;
- (IBAction) gotoPrevPage;
- (IBAction) increaseTextSizeClicked:(id)sender;
- (IBAction) decreaseTextSizeClicked:(id)sender;
- (IBAction) slidingStarted:(id)sender;
- (IBAction) slidingEnded:(id)sender;
- (IBAction) doneClicked:(id)sender;


//public methods
- (void) loadSpine:(int)spineIndex atPageIndex:(int)pageIndex highlightSearchResult:(SearchResult*)theResult;
- (void) loadEpub:(NSURL*) epubURL;



@end
