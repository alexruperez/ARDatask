Introduction
------------
ARDatask is a class that you can drop into any iPhone app (iOS 4.0 or later) that will help to ask some user data to tracking or analyze once they have used the application.
Read below for how to get started.


Getting Started
---------------
1. Add the ARDatask code into your project.
2. If your project doesn't use ARC, add the `-fobjc-arc` compiler flag to `ARDatask.m` in your target's Build Phases » Compile Sources section.
3. Add the `CFNetwork`, `SystemConfiguration`, and `StoreKit` frameworks to your project. Be sure to **change Required to Optional** for StoreKit in your target's Build Phases » Link Binary with Libraries section.
4. Call `[ARDatask appLaunched:YES];` at the end of your app delegate's `application:didFinishLaunchingWithOptions:` method.
5. Call `[ARDatask appEnteredForeground:YES];` in your app delegate's `applicationWillEnterForeground:` method.
6. Add an observer for `dataskDidOptToRequest` wherever you like to check when te user gives permission and show your data request form.
7. Call `[ARDatask setRequestCompleted:YES];` when you have the wanted user information.
6. (OPTIONAL) Call `[ARDatask userDidSignificantEvent:YES];` when the user does something 'significant' in the app.

Configuration
-------------

ARDatask provides class methods and some more notifications to configure its behavior. See [ARDatask.h](https://github.com/alexruperez/ARDatask/blob/master/ARDatask.h) for more information.

```objc
[ARDatask setDaysUntilPrompt:1];
[ARDatask setUsesUntilPrompt:10];
[ARDatask setSignificantEventsUntilPrompt:-1];
[ARDatask setTimeBeforeReminding:2];
[ARDatask setDebug:YES];
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(YOUR_METHOD) name:@"dataskDidOptToRequest" object:nil];
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(YOUR_METHOD) name:@"dataskDidDisplayAlert" object:nil];
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(YOUR_METHOD) name:@"dataskDidOptToRemindLater" object:nil];
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(YOUR_METHOD) name:@"dataskDidDismissModalView" object:nil];
```

License
-------
Copyright 2013. [alexruperez](https://github.com/alexruperez)
Based on [appirater](https://github.com/arashpayan/appirater)

While not required, I greatly encourage and appreciate any improvements that you make
to this library be contributed back for the benefit of all who use ARDatask.
