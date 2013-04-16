/*
 This file is part of ARDatask.
 
 Copyright (c) 2013, alexruperez
 All rights reserved.
 */
/*
 * ARDatask.h
 * ARDatask
 *
 * Created by alexruperez on 16/04/2013.
 * http://github.com/alexruperez
 * Copyright 2013 alexruperez. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

extern NSString *const kARDataskFirstUseDate;
extern NSString *const kARDataskUseCount;
extern NSString *const kARDataskSignificantEventCount;
extern NSString *const kARDataskRequestCompleted;
extern NSString *const kARDataskReminderRequestDate;

/*
 Your localized app's name.
 */
#define ARDATASK_LOCALIZED_APP_NAME    [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"]

/*
 Your app's name.
 */
#define ARDATASK_APP_NAME				ARDATASK_LOCALIZED_APP_NAME ? ARDATASK_LOCALIZED_APP_NAME : [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey]

/*
 This is the message your users will see once they've passed the day+launches
 threshold.
 */
#define ARDATASK_LOCALIZED_MESSAGE     NSLocalizedStringFromTable(@"If you enjoy using %@, would you mind taking a moment to give us your information? It won't take more than a minute. Thanks for your support!", @"ARDataskLocalizable", nil)
#define ARDATASK_MESSAGE				[NSString stringWithFormat:ARDATASK_LOCALIZED_MESSAGE, ARDATASK_APP_NAME]

/*
 This is the title of the message alert that users will see.
 */
#define ARDATASK_LOCALIZED_MESSAGE_TITLE   NSLocalizedStringFromTable(@"%@ Request", @"ARDataskLocalizable", nil)
#define ARDATASK_MESSAGE_TITLE             [NSString stringWithFormat:ARDATASK_LOCALIZED_MESSAGE_TITLE, ARDATASK_APP_NAME]

/*
 The text of the button that rejects reviewing the app.
 */
#define ARDATASK_REQUEST_BUTTON			NSLocalizedStringFromTable(@"Ok", @"ARDataskLocalizable", nil)

/*
 Text for button to remind the user to review later.
 */
#define ARDATASK_REQUEST_LATER			NSLocalizedStringFromTable(@"Remind me later", @"ARDataskLocalizable", nil)

@interface ARDatask : NSObject <UIAlertViewDelegate, SKStoreProductViewControllerDelegate> {

	UIAlertView *requestAlert;
}

@property(nonatomic, strong) UIAlertView *requestAlert;

/*
 Tells ARDatask that the app has launched, and on devices that do NOT
 support multitasking, the 'uses' count will be incremented. You should
 call this method at the end of your application delegate's
 application:didFinishLaunchingWithOptions: method.
 
 If the app has been used enough to ask for user data (and enough significant events),
 you can suppress the request
 by passing NO for canPromptForRequest. The request alert will simply be postponed
 until it is called again with YES for canPromptForRequest. The request alert
 can also be triggered by appEnteredForeground: and userDidSignificantEvent:
 (as long as you pass YES for canPromptForRequest in those methods).
 */
+ (void)appLaunched:(BOOL)canPromptForRequest;

/*
 Tells ARDatask that the app was brought to the foreground on multitasking
 devices. You should call this method from the application delegate's
 applicationWillEnterForeground: method.
 
 If the app has been used enough to ask for user data (and enough significant events),
 you can suppress the request alert
 by passing NO for canPromptForRequest. The request alert will simply be postponed
 until it is called again with YES for canPromptForRequest. The request alert
 can also be triggered by appLaunched: and userDidSignificantEvent:
 (as long as you pass YES for canPromptForRequest in those methods).
 */
+ (void)appEnteredForeground:(BOOL)canPromptForRequest;

/*
 Tells ARDatask that the user performed a significant event. A significant
 event is whatever you want it to be. If you're app is used to make VoIP
 calls, then you might want to call this method whenever the user places
 a call. If it's a game, you might want to call this whenever the user
 beats a level boss.
 
 If the user has performed enough significant events and used the app enough,
 you can suppress the request alert by passing NO for canPromptForRequest. The
 request alert will simply be postponed until it is called again with YES for
 canPromptForRequest. The request alert can also be triggered by appLaunched:
 and appEnteredForeground: (as long as you pass YES for canPromptForRequest
 in those methods).
 */
+ (void)userDidSignificantEvent:(BOOL)canPromptForRequest;

/*
 Tells ARDatask to show the prompt (a request alert). The prompt will be showed
 if there is connection available, the user hasn't declined to request
 or hasn't requested current version.
 
 You could call to show the prompt regardless ARDatask settings,
 e.g., in case of some special event in your app.
 */
+ (void)showPrompt;

/*
 Tells ARDatask to immediately close any open request modals (e.g. StoreKit request VCs).
*/
+ (void)closeModal;

@end

@interface ARDatask(Configuration)

/*
 Users will need to have the same version of your app installed for this many
 days before they will be prompted to ask for user data.
 */
+ (void) setDaysUntilPrompt:(double)value;

/*
 An example of a 'use' would be if the user launched the app. Bringing the app
 into the foreground (on devices that support it) would also be considered
 a 'use'. You tell ARDatask about these events using the two methods:
 [ARDatask appLaunched:]
 [ARDatask appEnteredForeground:]
 
 Users need to 'use' the same version of the app this many times before
 before they will be prompted to ask for user data.
 */
+ (void) setUsesUntilPrompt:(NSInteger)value;

/*
 A significant event can be anything you want to be in your app. In a
 telephone app, a significant event might be placing or receiving a call.
 In a game, it might be beating a level or a boss. This is just another
 layer of filtering that can be used to make sure that only the most
 loyal of your users are being prompted to ask for user data.
 If you leave this at a value of -1, then this won't be a criterion
 used for request. To tell ARDatask that the user has performed
 a significant event, call the method:
 [ARDatask userDidSignificantEvent:];
 */
+ (void) setSignificantEventsUntilPrompt:(NSInteger)value;


/*
 Once the request alert is presented to the user, they might select
 'Remind me later'. This value specifies how long (in days) ARDatask
 will wait before reminding them.
 */
+ (void) setTimeBeforeReminding:(double)value;

/*
 'YES' will show the ARDatask alert everytime. Useful for testing how your message
 looks and making sure all works.
 */
+ (void) setDebug:(BOOL)debug;

/*
 Set whether or not ARDatask uses animation (currently respected when pushing modal StoreKit request VCs).
 */
+ (void)setUsesAnimation:(BOOL)animation;

/*
 
 */
+ (void)setRequestCompleted:(BOOL)value;

@end


@interface ARDatask(Deprecated)

/*
 DEPRECATED: While still functional, it's better to use
 appLaunched:(BOOL)canPromptForRequest instead.
 
 Calls [ARDatask appLaunched:YES]. See appLaunched: for details of functionality.
 */
+ (void)appLaunched __attribute__((deprecated)); 

@end
