/*
 This file is part of ARDatask.
 
 Copyright (c) 2013, alexruperez
 All rights reserved.
 */
/*
 * ARDatask.m
 * ARDatask
 *
 * Created by alexruperez on 16/04/2013.
 * http://github.com/alexruperez
 * Copyright 2013 alexruperez. All rights reserved.
 */

#import "ARDatask.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

NSString *const kARDataskFirstUseDate				= @"kARDataskFirstUseDate";
NSString *const kARDataskUseCount					= @"kARDataskUseCount";
NSString *const kARDataskSignificantEventCount		= @"kARDataskSignificantEventCount";
NSString *const kARDataskRequestCompleted         = @"kARDataskRequestCompleted";
NSString *const kARDataskReminderRequestDate		= @"kARDataskReminderRequestDate";

static double _daysUntilPrompt = 30;
static NSInteger _usesUntilPrompt = 20;
static NSInteger _significantEventsUntilPrompt = -1;
static double _timeBeforeReminding = 1;
static BOOL _debug = NO;
static BOOL _usesAnimation = YES;
static UIStatusBarStyle _statusBarStyle;
static BOOL _modalOpen = NO;

@interface ARDatask ()
- (BOOL)connectedToNetwork;
- (void)showRequestAlert;
- (BOOL)requestConditionsHaveBeenMet;
- (void)incrementUseCount;
- (void)hideRequestAlert;
+ (ARDatask*)sharedInstance;
@end

@implementation ARDatask

@synthesize requestAlert;

+ (void) setDaysUntilPrompt:(double)value {
    _daysUntilPrompt = value;
}

+ (void) setUsesUntilPrompt:(NSInteger)value {
    _usesUntilPrompt = value;
}

+ (void) setSignificantEventsUntilPrompt:(NSInteger)value {
    _significantEventsUntilPrompt = value;
}

+ (void) setTimeBeforeReminding:(double)value {
    _timeBeforeReminding = value;
}

+ (void) setDebug:(BOOL)debug {
    _debug = debug;
}

+ (void)setUsesAnimation:(BOOL)animation {
	_usesAnimation = animation;
}

+ (void)setStatusBarStyle:(UIStatusBarStyle)style {
	_statusBarStyle = style;
}

+ (void)setModalOpen:(BOOL)open {
	_modalOpen = open;
}

+ (void)setRequestCompleted:(BOOL)value {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:kARDataskRequestCompleted];
    [userDefaults synchronize];
}

- (BOOL)connectedToNetwork {
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
	
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
	
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
	
    if (!didRetrieveFlags)
    {
        NSLog(@"Error. Could not recover network reachability flags");
        return NO;
    }
	
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
	
	NSURL *testURL = [NSURL URLWithString:@"http://www.apple.com/"];
	NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
	NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:self];
	
    return ((isReachable && !needsConnection) || nonWiFi) ? (testConnection ? YES : NO) : NO;
}

+ (ARDatask*)sharedInstance {
	static ARDatask *ardatask = nil;
	if (ardatask == nil)
	{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            ardatask = [[ARDatask alloc] init];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:
                UIApplicationWillResignActiveNotification object:nil];
        });
	}
	
	return ardatask;
}

- (void)showRequestAlert {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ARDATASK_MESSAGE_TITLE message:ARDATASK_MESSAGE delegate:self cancelButtonTitle:ARDATASK_REQUEST_LATER otherButtonTitles:ARDATASK_REQUEST_BUTTON, nil];
    
	self.requestAlert = alertView;
	[alertView show];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"dataskDidDisplayAlert" object:self];
}

- (BOOL)requestConditionsHaveBeenMet {
    
	if (_debug) return YES;
    
    // has the user already complete a request?
	if ([self userHasRequested])
		return NO;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSDate *dateOfFirstLaunch = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kARDataskFirstUseDate]];
	NSTimeInterval timeSinceFirstLaunch = [[NSDate date] timeIntervalSinceDate:dateOfFirstLaunch];
	NSTimeInterval timeUntilRequest = 60 * 60 * 24 * _daysUntilPrompt;
	if (timeSinceFirstLaunch < timeUntilRequest)
		return NO;
	
	// check if the app has been used enough
	int useCount = [userDefaults integerForKey:kARDataskUseCount];
	if (useCount <= _usesUntilPrompt)
		return NO;
	
	// check if the user has done enough significant events
	int sigEventCount = [userDefaults integerForKey:kARDataskSignificantEventCount];
	if (sigEventCount <= _significantEventsUntilPrompt)
		return NO;
	
	// if the user wanted to be reminded later, has enough time passed?
	NSDate *reminderRequestDate = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kARDataskReminderRequestDate]];
	NSTimeInterval timeSinceReminderRequest = [[NSDate date] timeIntervalSinceDate:reminderRequestDate];
	NSTimeInterval timeUntilReminder = 60 * 60 * 24 * _timeBeforeReminding;
	if (timeSinceReminderRequest < timeUntilReminder)
		return NO;
	
	return YES;
}

- (void)incrementUseCount {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
    // check if the first use date has been set. if not, set it.
    NSTimeInterval timeInterval = [userDefaults doubleForKey:kARDataskFirstUseDate];
    if (timeInterval == 0)
    {
        timeInterval = [[NSDate date] timeIntervalSince1970];
        [userDefaults setDouble:timeInterval forKey:kARDataskFirstUseDate];
    }
    
    // increment the use count
    int useCount = [userDefaults integerForKey:kARDataskUseCount];
    useCount++;
    [userDefaults setInteger:useCount forKey:kARDataskUseCount];
    if (_debug) NSLog(@"ARDATASK Use count: %d", useCount);
	
	[userDefaults synchronize];
}

- (void)incrementSignificantEventCount {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    // check if the first use date has been set. if not, set it.
    NSTimeInterval timeInterval = [userDefaults doubleForKey:kARDataskFirstUseDate];
    if (timeInterval == 0)
    {
        timeInterval = [[NSDate date] timeIntervalSince1970];
        [userDefaults setDouble:timeInterval forKey:kARDataskFirstUseDate];
    }
    
    // increment the significant event count
    int sigEventCount = [userDefaults integerForKey:kARDataskSignificantEventCount];
    sigEventCount++;
    [userDefaults setInteger:sigEventCount forKey:kARDataskSignificantEventCount];
    if (_debug) NSLog(@"ARDATASK Significant event count: %d", sigEventCount);
	
	[userDefaults synchronize];
}

- (void)incrementAndRequest:(BOOL)canPromptForRequest {
	[self incrementUseCount];
	
	if (canPromptForRequest &&
		[self requestConditionsHaveBeenMet] &&
		[self connectedToNetwork])
	{
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self showRequestAlert];
                       });
	}
}

- (void)incrementSignificantEventAndRequest:(BOOL)canPromptForRequest {
	[self incrementSignificantEventCount];
	
	if (canPromptForRequest &&
		[self requestConditionsHaveBeenMet] &&
		[self connectedToNetwork])
	{
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self showRequestAlert];
                       });
	}
}

- (BOOL)userHasRequested {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kARDataskRequestCompleted];
}

+ (void)appLaunched {
	[ARDatask appLaunched:YES];
}

+ (void)appLaunched:(BOOL)canPromptForRequest {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[ARDatask sharedInstance] incrementAndRequest:canPromptForRequest];
                   });
}

- (void)hideRequestAlert {
	if (self.requestAlert.visible) {
		if (_debug) NSLog(@"ARDATASK Hiding Alert");
		[self.requestAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}	
}

+ (void)appWillResignActive {
	if (_debug) NSLog(@"ARDATASK appWillResignActive");
	[[ARDatask sharedInstance] hideRequestAlert];
}

+ (void)appEnteredForeground:(BOOL)canPromptForRequest {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[ARDatask sharedInstance] incrementAndRequest:canPromptForRequest];
                   });
}

+ (void)userDidSignificantEvent:(BOOL)canPromptForRequest {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [[ARDatask sharedInstance] incrementSignificantEventAndRequest:canPromptForRequest];
                   });
}

+ (void)showPrompt {
    if ([[ARDatask sharedInstance] connectedToNetwork]
        && ![[ARDatask sharedInstance] userHasRequested]) {
        [[ARDatask sharedInstance] showRequestAlert];
    }
}

+ (id)getRootViewController {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(window in windows) {
            if (window.windowLevel == UIWindowLevelNormal) {
                break;
            }
        }
    }
    
    for (UIView *subView in [window subviews])
    {
        UIResponder *responder = [subView nextResponder];
        if([responder isKindOfClass:[UIViewController class]]) {
            return [self topMostViewController: (UIViewController *) responder];
        }
    }
    
    return nil;
}

+ (UIViewController *) topMostViewController: (UIViewController *) controller {
	BOOL isPresenting = NO;
	do {
		// this path is called only on iOS 6+, so -presentedViewController is fine here.
		UIViewController *presented = [controller presentedViewController];
		isPresenting = presented != nil;
		if(presented != nil) {
			controller = presented;
		}
		
	} while (isPresenting);
	
	return controller;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	
	
	switch (buttonIndex) {
		case 0:
		{
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kARDataskReminderRequestDate];
            [userDefaults synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"dataskDidOptToRemindLater" object:self];
			break;
		}
        
		case 1:
		{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"dataskDidOptToRequest" object:self];
			break;
		}
        
		default:
			break;
	}
}

//Delegate call from the StoreKit view.
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
	[ARDatask closeModal];
}

//Close the in-app request view and restore the previous status bar style.
+ (void)closeModal {
	if (_modalOpen) {
		[[UIApplication sharedApplication]setStatusBarStyle:_statusBarStyle animated:_usesAnimation];
		[self setModalOpen:NO];
		
		// get the top most controller (= the StoreKit Controller) and dismiss it
		UIViewController *presentingController = [UIApplication sharedApplication].keyWindow.rootViewController;
		presentingController = [self topMostViewController: presentingController];
		[presentingController dismissViewControllerAnimated:_usesAnimation completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"dataskDidDismissModalView" object:self];
		}];
		[self.class setStatusBarStyle:(UIStatusBarStyle)nil];
	}
}

@end
