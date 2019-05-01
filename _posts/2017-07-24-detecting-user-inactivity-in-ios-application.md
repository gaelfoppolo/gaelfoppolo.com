---
title: Detecting user inactivity in iOS application!
date: 2017-07-24
categories: [ios, ux, security]
excerpt: iOS already offers an auto-lock system but what if you need more control, more granularity?

---

One of my main task nowadays is to develop new applications from scratch.

The company I currently work for provide numerous health services and this new app I was asked to create is one of them. And of course, as any service, it has to deal with data.

However, health is one of these fields where privacy is one of the top priority. Guidelines must be follow regarding security, to keep data safe and private.

Hence, in order to prevent data leak and offer the best security possible, one of the security measure, we must provide is to lock the system after a some time of inactivity. By lock, we mean shut down the access, and in the context of the app, disconnect the user. The user must then log in to access the app and its data.

That’s where the problem is: how to detect the inactivity of the user in our app and perform actions? In our case, disconnecting the user.

To do that, first we need to go back to basis and understand how iOS app are launched and how the events are handled.

# UIApplication

Every iOS app has exactly one instance of `UIApplication`, which is responsible for handling and routing user event to the good objects. That’s where we need to dive into, because we want to be at the lowest level possible.

First things first, when this instance is created?

Well the creation is the responsibility of one method, `UIApplicationMain(_:_:_:_:)`.

> This function instantiates the application object from the principal class and instantiates the delegate (if any) from the given class and sets the delegate for the application. It also sets up the main event loop, including the application’s run loop, and begins processing events.
>
> — [Apple Documentation](https://developer.apple.com/documentation/uikit/1622933-uiapplicationmain)

But same problem apply here, when did that method is called?

As a matter of fact, did you ever notice there is no entry point, or main method in an iOS app? Well, that is not entirely true. In Objective-C, there is one, and it calls the `UIApplicationMain(_:_:_:_:)` method I mention just before.

Okay that solve one problem. But where did it go in Swift based app?

I’m sure you already took a closer look at the `AppDelegate.swift` file and notice the `@UIApplicationMain` attribute at the top of the class.

> Apply this attribute to a class to indicate that it is the application delegate. Using this attribute is equivalent to calling the `UIApplicationMain` function and passing this class’s name as the name of the delegate class.
>
> — [Swift, Language Reference, Attributes](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html)

So basically, in Swift app, the main file is not needed when using this attribute ; all we need to do is provide a delegate, by default the `AppDelegate` class, and the system will handle the call for us. Really handy.

A little chart to synthesis what we saw:

{% include 
    image.html 
    src="ios-uiapplication-lifecyle.png"
    alt="Default behavior"
    caption="Default behavior of UIApplication"
%}

When the app is launched, the `UIApplication` is created and then when everything is ready, the delegate `UIApplicationDelegate` is called, thanks to its delegate method `application(didFinishLaunchingWithOptions:)` allowing us to perform custom setup (or not if you’re using Storyboard). I will assume you know how to do this part.

Okay, okay, back to our problem. We want to monitor all of the user events, do our little custom work, and propagate the events to its rightful control objects. And we want to do in our whole app, quickly, easily, without adding protocol and code everywhere. That would be messy really quick.

# Our custom UIApplication

We said that the `UIApplication` singleton is responsible for handling user events. Well to do our custom actions, let’s simply subclass it and use it, instead of the default one.

Here is the code of our `TimerApplication`:

```swift
import UIKit

class TimerApplication: UIApplication {

    // the timeout in seconds, after which should perform custom actions
    // such as disconnecting the user
    private var timeoutInSeconds: TimeInterval {
        // 2 minutes
        return 2 * 60
    }

    private var idleTimer: Timer?

    // resent the timer because there was user interaction
    private func resetIdleTimer() {
        if let idleTimer = idleTimer {
            idleTimer.invalidate()
        }

        idleTimer = Timer.scheduledTimer(timeInterval: timeoutInSeconds,
                                         target: self,
                                         selector: #selector(TimerApplication.timeHasExceeded),
                                         userInfo: nil,
                                         repeats: false
        )
    }

    // if the timer reaches the limit as defined in timeoutInSeconds, post this notification
    @objc private func timeHasExceeded() {
        NotificationCenter.default.post(name: .appTimeout,
                                        object: nil
        )
    }

    override func sendEvent(_ event: UIEvent) {

        super.sendEvent(event)

        if idleTimer != nil {
            self.resetIdleTimer()
        }

        if let touches = event.allTouches {
            for touch in touches where touch.phase == UITouchPhase.began {
                self.resetIdleTimer()
            }
        }
    }
}
```

The code is easy to understand: we define a timer, and whenever a touch on the screen occurs, we reset this timer. If the timer reach its limit, we post a notification.

About notification, you might notice I use an enum. I prefer to do like this when I use notification, it’s clean and easily maintainable. To define it, do like this:

```swift
import Foundation

extension Notification.Name {

    static let appTimeout = Notification.Name("appTimeout")

}
```

The last method, `sendEvent(_)` is the most interesting. Calling the parent method at first will dispatch the event that we intercept back to the system. Then we check the event is a touch screen event, and if so reset the timer.

Okay. So now, we have a working system that can monitor user events without interfering and notify us when some conditions are reunited, in our case, a timing condition.

But how to use our custom subclass as the default `UIApplication` instance at app launch?

# Back to Objective-C?!

As I said, the attribute `@UIApplicationMain` is a shortcut that will call the `UIApplicationMain()` method, which is responsible for creating the `UIApplication` singleton. Did you remember how Objective-C does it? All we have to do is call `UIApplicationMain(_:_:_:_:)` by ourself and passing it our `UIApplication` sublass.

Simply create a `main.swift` file (the name of the file is important), and add this in:

```swift
import UIKit

UIApplicationMain(
    CommandLine.argc,
    UnsafeMutableRawPointer(CommandLine.unsafeArgv)
        .bindMemory(
            to: UnsafeMutablePointer<Int8>.self,
            capacity: Int(CommandLine.argc)),
    NSStringFromClass(TimerApplication.self),
    NSStringFromClass(AppDelegate.self)
)
```

Let’s analyze it, part by part. The method takes four parameters:

## `argc`

The count of arguments in `argv`; this is provided by the [`CommandLine`](https://developer.apple.com/documentation/swift/commandline) enum ;

## `argv`

A variable list of arguments; this is also provided by the [`CommandLine`](https://developer.apple.com/documentation/swift/commandline) enum ; the little hack is due to a mismatch in the type, [see SR-1390](https://bugs.swift.org/browse/SR-1390)

## `principalClassName`

The name of the [`UIApplication`](https://developer.apple.com/documentation/uikit/uiapplication) class or subclass. If you specify nil, UIApplication is assumed ; we want to use our subclass, we provide it ;

## `delegateClassName`

The name of the class from which the application delegate is instantiated, must conform to [`UIApplicationDelegate`](https://developer.apple.com/documentation/uikit/uiapplication) protocol ; `AppDelegate` still do the job ;

Finally, remove `@UIApplicationMain` from **AppDelegate** and you’re done! Build & run.. and still nothing happens!

That’s normal, we forgot to add an observer to our notification!

## Handling notification

For this part, I choose to do all the handling in **AppDelegate**, because I wanted to monitor the events from the start.

Add the following method in **AppDelegate:**

```swift
func applicationDidTimeout(notification: NSNotification) {

	print("application did timeout, perform actions")

}
```

And then register the observer in `application:didFinishLaunchingWithOptions`, like this:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
	
	/* ... */
	
	NotificationCenter.default.addObserver(self,
					       selector: #selector(AppDelegate.applicationDidTimeout(notification:)),
					       name: .appTimeout,
					       object: nil
	)
	
	/* ... */

	return true
}
```

The method `applicationDidTimeout` will be call after a certain time of inactivity and you can perform your custom actions.

{% include 
    image.html 
    src="ios-our-uiapplication-lifecyle.png"
    alt="Our behavior of UIApplication"
    caption="Our behavior of UIApplication"
%}

# Review

As any solution, it has its strengths and weaknesses.

### Strengths

* we did not modify a lot of code of our app

* the process is low-level

* our subclass of `UIApplication` is independent, we can add or modify the conditions of inactivity without impacting the rest of the app

* notification allows us to handle the event anywhere in the app ; we could extend the `UIApplicationDelegate` and provide and a new delegate method, but then we could only handle in the ***AppDelegate*** ; in my example I handle in the ***AppDelegate***, because of the context, but you could start observing the notification later in your app flow

### Weaknesses

* process is kind of heavy for small app, with one or two views (like game) ; instead apply it directly on the views

* the timeout is setup right after the first touch ; what if you only want to enable it after some point in your app (like login screen, menu)? We could add helpers functions such as enable/disable timer for example

* the timer continues after the app goes to background or the device is locked ; we could enable/disable the timer or register/unregister the notification in `applicationDidBecomeActive` and `applicationWillResignActive` for example

# Conclusion

Our problem is now resolved! We are notified of user inactivity and we can take measures, depending on the context, such as:

* show a message, maybe the user is stucked on something (help, UX)

* disconnect the user (security)

* launch an idlling mode (power)

* etc.

# References

[https://developer.apple.com/documentation/uikit/uiapplication](https://developer.apple.com/documentation/uikit/uiapplication)

[https://developer.apple.com/documentation/uikit/uiapplicationdelegate](https://developer.apple.com/documentation/uikit/uiapplicationdelegate)

[https://developer.apple.com/documentation/uikit/1622933-uiapplicationmain](https://developer.apple.com/documentation/uikit/1622933-uiapplicationmain)

[https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Attributes.html](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Attributes.html)

[https://developer.apple.com/documentation/swift/commandline](https://developer.apple.com/documentation/swift/commandline)

[https://bmnotes.com/2017/05/30/swift-no-main-method-no-entry-point-ios-app/](https://bmnotes.com/2017/05/30/swift-no-main-method-no-entry-point-ios-app/)

[https://oleb.net/blog/2012/02/app-launch-sequence-ios-revisited/](https://oleb.net/blog/2012/02/app-launch-sequence-ios-revisited/)