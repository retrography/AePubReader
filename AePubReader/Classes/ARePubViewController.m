//
//  AREPubViewController.m
//  AePubReader
//
//  Created by Abdul Rehman (abduliam) on 04/02/2013.
//  Copyright (c) 2013 StudioNorth, Lahore. All rights reserved.
//

#import "ARePubViewController.h"
#import "ARePubPageContentViewController.h"
#import "ChapterListViewController.h"
#import "SearchResultsViewController.h"
#import "SearchResult.h"

#import "UIWebView+SearchWebView.h"

@interface ARePubViewController () {
    BOOL _isMovingToNextPage;
}

@property(nonatomic,retain)UIPageViewController *pageVC;
@property(atomic,retain)ARePubPageContentViewController *currentPageVC;
@property(atomic,retain)ARePubPageContentViewController *nextPageVC;
@property(atomic,retain)ARePubPageContentViewController *prevPageVC;

@property (nonatomic,assign) BOOL hasNextPage;
@property (nonatomic,assign) BOOL hasPrevPage;

- (int) getGlobalPageCount;

- (void) updatePagination;

- (void) loadSpine:(int)spineIndex atPageIndex:(int)pageIndex;

- (void)updateDataForNextAndPreviousPages;

@end

@implementation ARePubViewController

#pragma mark - Object Lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    self.pageVC=nil;
    self.currentPageVC=nil;
    self.nextPageVC=nil;
    self.prevPageVC=nil;

    //epubvc
    self.toolbar = nil;
	self.chapterListButton = nil;
	self.decTextSizeButton = nil;
	self.incTextSizeButton = nil;
	self.pageSlider = nil;
	self.currentPageLabel = nil;
    self.loadedEpub=nil;
	[chaptersPopover release];
	[searchResultsPopover release];
	[searchResViewController release];
    
    self.currentSearchResult=nil;

    [super dealloc];
}

#pragma mark - UIViewController Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //begin create paging vc
    self.pageVC=[[[UIPageViewController alloc] initWithTransitionStyle:(UIPageViewControllerTransitionStylePageCurl) navigationOrientation:(UIPageViewControllerNavigationOrientationHorizontal) options:nil] autorelease];
    CGRect pageVCFrame=self.view.bounds;
    pageVCFrame.origin.y=44;
    pageVCFrame.size.height-=88;
    self.pageVC.view.frame=pageVCFrame;
    [self.view addSubview:self.pageVC.view];
    
    self.pageVC.delegate=self;
    self.pageVC.dataSource=self;
    [self addChildViewController:self.pageVC];
    [self.view sendSubviewToBack:self.pageVC.view];
    
    
    self.currentPageVC=[[[ARePubPageContentViewController alloc] initWithNibName:@"ARePubPageContentViewController" bundle:nil] autorelease];
    self.nextPageVC=[[[ARePubPageContentViewController alloc] initWithNibName:@"ARePubPageContentViewController" bundle:nil] autorelease];
    self.prevPageVC=[[[ARePubPageContentViewController alloc] initWithNibName:@"ARePubPageContentViewController" bundle:nil] autorelease];
    self.currentPageVC.ePubVC=self;
    self.nextPageVC.ePubVC=self;
    self.prevPageVC.ePubVC=self;

    //for debugging
    self.prevPageVC.title=@"0";
    self.currentPageVC.title=@"1";
    self.nextPageVC.title=@"2";
    
    [self.pageVC setViewControllers:@[self.currentPageVC] direction:(UIPageViewControllerNavigationDirectionForward) animated:NO completion:^(BOOL finished) {
        
    }];
    //end create paging vc
    
    self.currentTextSize = 100;

    searchResViewController = [[SearchResultsViewController alloc] initWithNibName:@"SearchResultsViewController" bundle:[NSBundle mainBundle]];
	searchResViewController.epubViewController = self;
}

- (void)viewDidUnload {
    self.currentPageVC=nil;
    self.nextPageVC=nil;
    self.prevPageVC=nil;
    self.pageVC=nil;
    
    //epub
    self.toolbar = nil;
    //	self.webView = nil;
	self.chapterListButton = nil;
	self.decTextSizeButton = nil;
	self.incTextSizeButton = nil;
	self.pageSlider = nil;
	self.currentPageLabel = nil;
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Rotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}












#pragma mark - IBActions
- (void) gotoNextPage {
    if (!self.paginating && self.hasNextPage) {
        [self.pageVC setViewControllers:@[self.nextPageVC] direction:(UIPageViewControllerNavigationDirectionForward) animated:YES completion:^(BOOL finished) {
            ARePubPageContentViewController *temp=[self.currentPageVC retain];
            self.currentPageVC=self.nextPageVC;
            self.nextPageVC=self.self.prevPageVC;
            self.prevPageVC=temp;
            [temp release];
            [self updateDataForNextAndPreviousPages];
        }];
    }
}

- (void) gotoPrevPage {
    if (!self.paginating && self.hasPrevPage) {
        [self.pageVC setViewControllers:@[self.prevPageVC] direction:(UIPageViewControllerNavigationDirectionReverse) animated:YES completion:^(BOOL finished) {
            ARePubPageContentViewController *temp=[self.currentPageVC retain];
            self.currentPageVC=self.prevPageVC;
            self.prevPageVC=self.nextPageVC;
            self.nextPageVC=temp;
            [temp release];
            [self updateDataForNextAndPreviousPages];
        }];
    }
}

- (IBAction) increaseTextSizeClicked:(id)sender{
	if(!self.paginating){
		if(self.currentTextSize+25<=200){
			self.currentTextSize+=25;
			[self updatePagination];
			if(self.currentTextSize == 200){
				[self.incTextSizeButton setEnabled:NO];
			}
			[self.decTextSizeButton setEnabled:YES];
		}
	}
}
- (IBAction) decreaseTextSizeClicked:(id)sender{
	if(!self.paginating){
		if(self.currentTextSize-25>=50){
			self.currentTextSize=self.currentTextSize-25;
			[self updatePagination];
			if(self.currentTextSize==50){
				[self.decTextSizeButton setEnabled:NO];
			}
			[self.incTextSizeButton setEnabled:YES];
		}
	}
}

- (IBAction) doneClicked:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
    
}


- (IBAction) slidingStarted:(id)sender{
    int targetPage = ((self.pageSlider.value/(float)100)*(float)self.totalPagesCount);
    if (targetPage==0) {
        targetPage++;
    }
	[self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d", targetPage, self.totalPagesCount]];
}

- (IBAction) slidingEnded:(id)sender{
	int targetPage = (int)((self.pageSlider.value/(float)100)*(float)self.totalPagesCount);
    if (targetPage==0) {
        targetPage++;
    }
	int pageSum = 0;
	int chapterIndex = 0;
	int pageIndex = 0;
	for(chapterIndex=0; chapterIndex<[self.loadedEpub.spineArray count]; chapterIndex++){
		pageSum+=[[self.loadedEpub.spineArray objectAtIndex:chapterIndex] pageCount];
        //		NSLog(@"Chapter %d, targetPage: %d, pageSum: %d, pageIndex: %d", chapterIndex, targetPage, pageSum, (pageSum-targetPage));
		if(pageSum>=targetPage){
			pageIndex = [[self.loadedEpub.spineArray objectAtIndex:chapterIndex] pageCount] - 1 - pageSum + targetPage;
			break;
		}
	}
	[self loadSpine:chapterIndex atPageIndex:pageIndex];
}

- (IBAction) showChapterIndex:(id)sender{
	if(chaptersPopover==nil){
		ChapterListViewController* chapterListView = [[ChapterListViewController alloc] initWithNibName:@"ChapterListViewController" bundle:[NSBundle mainBundle]];
		[chapterListView setEpubViewController:self];
		chaptersPopover = [[UIPopoverController alloc] initWithContentViewController:chapterListView];
		[chaptersPopover setPopoverContentSize:CGSizeMake(400, 600)];
		[chapterListView release];
	}
	if ([chaptersPopover isPopoverVisible]) {
		[chaptersPopover dismissPopoverAnimated:YES];
	}else{
		[chaptersPopover presentPopoverFromBarButtonItem:self.chapterListButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	if(searchResultsPopover==nil){
		searchResultsPopover = [[UIPopoverController alloc] initWithContentViewController:searchResViewController];
		[searchResultsPopover setPopoverContentSize:CGSizeMake(400, 600)];
	}
	if (![searchResultsPopover isPopoverVisible]) {
		[searchResultsPopover presentPopoverFromRect:searchBar.bounds inView:searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
    //	NSLog(@"Searching for %@", [searchBar text]);
	if(!self.searching){
		self.searching = YES;
		[searchResViewController searchString:[searchBar text]];
        [searchBar resignFirstResponder];
	}
}


#pragma mark - ePub management
- (void)loadEpub:(NSURL*) epubURL{
    self.currentPageVC.currentPageSpineIndex = 0;
    self.currentPageVC.currentPageInSpineIndex = 0;
    self.currentPageVC.pagesInCurrentSpineCount = 0;
    self.totalPagesCount = 0;
	self.searching = NO;
    self.epubLoaded = NO;
    self.loadedEpub = [[[EPub alloc] initWithEPubPath:[epubURL path]] autorelease];
    self.epubLoaded = YES;
    NSLog(@"loadEpub");
	[self updatePagination];
}

- (void)loadSpine:(int)spineIndex atPageIndex:(int)pageIndex highlightSearchResult:(SearchResult*)theResult {
	
	self.currentPageVC.webView.hidden = YES;
	self.currentSearchResult = theResult;
    
	[chaptersPopover dismissPopoverAnimated:YES];
	[searchResultsPopover dismissPopoverAnimated:YES];
    
    Chapter *currentChapter=[self.loadedEpub.spineArray objectAtIndex:spineIndex];
	
	NSURL* currentUrl = [NSURL fileURLWithPath:[currentChapter spinePath]];
	[self.currentPageVC.webView loadRequest:[NSURLRequest requestWithURL:currentUrl]];

    self.currentPageVC.currentPageURL=currentUrl;
    self.currentPageVC.currentPageSpineIndex=spineIndex;
    self.currentPageVC.currentPageInSpineIndex=pageIndex;
    
	if(!self.paginating){
		[self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], self.totalPagesCount]];
		[self.pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)self.totalPagesCount animated:YES];
	}
    [self updateDataForNextAndPreviousPages];//KABOOM: may need to change this when paginating has not ended
}

#pragma mark - Private
- (int) getGlobalPageCount{
	int pageCount = 0;
	for(int i=0; i<self.currentPageVC.currentPageSpineIndex; i++){
		pageCount+= [[self.loadedEpub.spineArray objectAtIndex:i] pageCount];
	}
	pageCount+=self.currentPageVC.currentPageInSpineIndex+1;
	return pageCount;
}

- (void) updatePagination{
	if(self.epubLoaded){
        if(!self.paginating){
            NSLog(@"Pagination Started!");
            self.paginating = YES;
            self.totalPagesCount=0;
            [self loadSpine:self.currentPageVC.currentPageSpineIndex atPageIndex:self.currentPageVC.currentPageInSpineIndex];
            [[self.loadedEpub.spineArray objectAtIndex:0] setDelegate:self];
            [[self.loadedEpub.spineArray objectAtIndex:0] loadChapterWithWindowSize:self.currentPageVC.webView.bounds fontPercentSize:self.currentTextSize];
            [self.currentPageLabel setText:@"?/?"];
        }
	}
}

- (void) loadSpine:(int)spineIndex atPageIndex:(int)pageIndex {
	[self loadSpine:spineIndex atPageIndex:pageIndex highlightSearchResult:nil];
}

- (void)updateDataForNextAndPreviousPages {
    //KABOOM: need to improve loading on as required (we don't always need to load next and previous pages)
    int nextPageSpineIndex=self.currentPageVC.currentPageSpineIndex;
    int nextPageInSpineIndex=self.currentPageVC.currentPageInSpineIndex+1;
    
    Chapter *nextChapter=nil;
    if (nextPageSpineIndex<[self.loadedEpub.spineArray count] && nextPageSpineIndex>=0) {
        nextChapter=[self.loadedEpub.spineArray objectAtIndex:nextPageSpineIndex];
        
        //first check if we reached the last page, move to next spine if possiable
        if (nextPageInSpineIndex>=nextChapter.pageCount) {
            nextPageSpineIndex++;
            nextPageInSpineIndex=0;
            nextChapter=nil;
            if (nextPageSpineIndex<[self.loadedEpub.spineArray count]) {
                nextChapter=[self.loadedEpub.spineArray objectAtIndex:nextPageSpineIndex];
            }
        }
    }
    NSString *nextSpinePath=[nextChapter spinePath];
    if (nextSpinePath) {
        NSURL *spineURL=[NSURL fileURLWithPath:nextSpinePath];
        self.nextPageVC.currentPageURL=spineURL;
        self.nextPageVC.currentPageSpineIndex=nextPageSpineIndex;
        self.nextPageVC.currentPageInSpineIndex=nextPageInSpineIndex;
        self.hasNextPage=YES;
    }else{
        self.hasNextPage=NO;
    }
    
    
    int prevPageSpineIndex=self.currentPageVC.currentPageSpineIndex;
    int prevPageInSpineIndex=self.currentPageVC.currentPageInSpineIndex-1;
    
    Chapter *prevChapter=nil;
    if (prevPageSpineIndex<[self.loadedEpub.spineArray count] && prevPageSpineIndex>=0) {
        prevChapter=[self.loadedEpub.spineArray objectAtIndex:prevPageSpineIndex];
        
        //first check if we reached the first page, move to previous spine if possiable
        if (prevPageInSpineIndex<0) {
            prevPageSpineIndex--;
            prevChapter=nil;
            if (prevPageSpineIndex>=0) {
                prevChapter=[self.loadedEpub.spineArray objectAtIndex:prevPageSpineIndex];
                prevPageInSpineIndex=prevChapter.pageCount;
            }
        }
    }
    NSString *prevSpinePath=[prevChapter spinePath];
    if (prevSpinePath) {
        NSURL *spineURL=[NSURL fileURLWithPath:prevSpinePath];
        self.prevPageVC.currentPageURL=spineURL;
        self.prevPageVC.currentPageSpineIndex=prevPageSpineIndex;
        self.prevPageVC.currentPageInSpineIndex=prevPageInSpineIndex;
        self.hasPrevPage=YES;
    }else{
        self.hasPrevPage=NO;
    }
    
    if(!self.paginating){
        [self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], self.totalPagesCount]];
        [self.pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)self.totalPagesCount animated:YES];
    }
}

#pragma mark - ILChaperDelegate impl
- (void) chapterDidFinishLoad:(Chapter *)chapter{
    self.totalPagesCount+=chapter.pageCount;
    
	if(chapter.chapterIndex + 1 < [self.loadedEpub.spineArray count]){
		[[self.loadedEpub.spineArray objectAtIndex:chapter.chapterIndex+1] setDelegate:self];
		[[self.loadedEpub.spineArray objectAtIndex:chapter.chapterIndex+1] loadChapterWithWindowSize:self.currentPageVC.webView.bounds fontPercentSize:self.currentTextSize];
		[self.currentPageLabel setText:[NSString stringWithFormat:@"?/%d", self.totalPagesCount]];
	} else {
		[self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], self.totalPagesCount]];
		[self.pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)self.totalPagesCount animated:YES];
		self.paginating = NO;
		NSLog(@"Pagination Ended!");
	}
}

#pragma mark - UIPageViewControllerDelegate && UIPageViewControllerDatasource impl
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    UIViewController *vc=nil;
    if (self.hasPrevPage && !self.paginating) {
        _isMovingToNextPage=NO;
        vc=self.prevPageVC;
    }
    NSLog(@"viewControllerBeforeViewController hasPrevPage:%d", self.hasPrevPage);
    return vc;
}
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    UIViewController *vc=nil;
    if (self.hasNextPage && !self.paginating) {
        _isMovingToNextPage=YES;
        vc=self.nextPageVC;
    }
    NSLog(@"viewControllerAfterViewController hasNextPage:%d", self.hasNextPage);
    return vc;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    NSLog(@"didFinishAnimating transitionCompleted:%d", completed);
    for (UIViewController *prev in previousViewControllers) {
        NSLog(@"previousViewController: %@", prev.title);
    }
    
    if (completed) {
        if (_isMovingToNextPage) {
            ARePubPageContentViewController *temp=[self.currentPageVC retain];
            self.currentPageVC=self.nextPageVC;
            self.nextPageVC=self.self.prevPageVC;
            self.prevPageVC=temp;
            [temp release];
        }else{
            ARePubPageContentViewController *temp=[self.currentPageVC retain];
            self.currentPageVC=self.prevPageVC;
            self.prevPageVC=self.nextPageVC;
            self.nextPageVC=temp;
            [temp release];
        }
        [self updateDataForNextAndPreviousPages];
    }
}

@end
