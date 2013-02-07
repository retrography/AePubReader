//
//  ARePubPageViewController.h
//  AePubReader
//
//  Created by Abdul Rehman (abduliam) on 06/02/2013.
//  Copyright (c) 2013 StudioNorth, Lahore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ARePubViewController;

//
//  For internal use in ARePubViewController
//
@interface ARePubPageContentViewController : UIViewController <UIWebViewDelegate>

@property (assign, nonatomic) ARePubViewController *ePubVC;
@property (retain, nonatomic) IBOutlet UIWebView *webView;


@property (nonatomic,retain) NSURL *currentPageURL;
@property (nonatomic,assign) int currentPageSpineIndex;
@property (nonatomic,assign) int currentPageInSpineIndex;
@property (nonatomic,assign) int pagesInCurrentSpineCount;

@end
