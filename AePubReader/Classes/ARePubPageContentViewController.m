//
//  ARePubPageViewController.m
//  AePubReader
//
//  Created by Abdul Rehman (abduliam) on 06/02/2013.
//  Copyright (c) 2013 StudioNorth, Lahore. All rights reserved.
//

#import "ARePubPageContentViewController.h"
#import "ARePubViewController.h"

#import "SearchResultsViewController.h"
#import "SearchResult.h"

#import "UIWebView+SearchWebView.h"


@interface ARePubPageContentViewController ()

@end

@implementation ARePubPageContentViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    self.webView.delegate=nil;
    [_webView release];
    self.ePubVC=nil;
    self.currentPageURL=nil;
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	UIScrollView* sv = nil;
	for (UIView* v in  self.webView.subviews) {
		if([v isKindOfClass:[UIScrollView class]]){
			sv = (UIScrollView*) v;
			sv.scrollEnabled = NO;
			sv.bounces = NO;
		}
	}
    self.webView.delegate=self;
}

- (void)viewDidUnload {
    self.webView.delegate=nil;
    [self setWebView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.currentPageURL]];
//    self.webView.hidden=YES;
    NSLog(@"viewWillAppear: %@ ", self.title);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    [self gotoPageInCurrentSpine:self.currentPageInSpineIndex];
    
    //KABOOM: just setting the offset doesn't work with images in book, so reload the page
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.currentPageURL]];
    
}

#pragma mark - User defined
- (void)gotoPageInCurrentSpine:(int)pageIndex {
	if(pageIndex>=self.pagesInCurrentSpineCount){
		pageIndex = self.pagesInCurrentSpineCount - 1;
		self.currentPageInSpineIndex = self.pagesInCurrentSpineCount - 1;
	}
    if (pageIndex<0) {
        pageIndex=0;
    }
	
	float pageOffset = pageIndex*self.webView.bounds.size.width;
    
	NSString* goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(xOffset){ window.scroll(xOffset,0); } "];
	NSString* goTo =[NSString stringWithFormat:@"pageScroll(%f)", pageOffset];
	
	[self.webView stringByEvaluatingJavaScriptFromString:goToOffsetFunc];
	[self.webView stringByEvaluatingJavaScriptFromString:goTo];
	
	self.webView.hidden = NO;
}

#pragma mark - UIWebViewDelegate impl
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *varMySheet = @"var mySheet = document.styleSheets[0];";
	
	NSString *addCSSRule =  @"function addCSSRule(selector, newRule) {"
	"if (mySheet.addRule) {"
	"mySheet.addRule(selector, newRule);"								// For Internet Explorer
	"} else {"
	"ruleIndex = mySheet.cssRules.length;"
	"mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"   // For Firefox, Chrome, etc.
	"}"
	"}";
	
	NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", webView.frame.size.height, webView.frame.size.width];
	NSString *insertRule2 = [NSString stringWithFormat:@"addCSSRule('p', 'text-align: justify;')"];
	NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", self.ePubVC.currentTextSize];
	NSString *setHighlightColorRule = [NSString stringWithFormat:@"addCSSRule('highlight', 'background-color: yellow;')"];
    
	
	[webView stringByEvaluatingJavaScriptFromString:varMySheet];
	
	[webView stringByEvaluatingJavaScriptFromString:addCSSRule];
    
	[webView stringByEvaluatingJavaScriptFromString:insertRule1];
	
	[webView stringByEvaluatingJavaScriptFromString:insertRule2];
	
	[webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
	
	[webView stringByEvaluatingJavaScriptFromString:setHighlightColorRule];
	
	if(self.ePubVC.currentSearchResult!=nil){
        //	NSLog(@"Highlighting %@", currentSearchResult.originatingQuery);
        [webView highlightAllOccurencesOfString:self.ePubVC.currentSearchResult.originatingQuery];
	}
	
	
    int totalWidth = [[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] intValue];
    self.pagesInCurrentSpineCount = (int)((float)totalWidth/webView.bounds.size.width);
    
    [self gotoPageInCurrentSpine:self.currentPageInSpineIndex];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

@end
