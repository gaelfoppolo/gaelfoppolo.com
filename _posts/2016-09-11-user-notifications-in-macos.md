---
title: User Notifications in macOS
date: 2016-09-11
categories: [macos]

---

**User Notifications** notify the user that something has changed in the application. Best known examples are the upcoming events in *Calendar* or the build status in *Xcode*.

[Notification Center](https://support.apple.com/en-us/HT204079) provides an overview of notifications from applications. As we will see, it’s very easy to integrate and display basic notifications in it.

Three display styles are available: **None**, **Banner** and **Alert**.

{% asset user-notifications-style.png %}

By default, User Notifications are displayed using the **Banner** style.

## Basic notification: banner

Banners are simple notification view, dismissed after a few seconds.

We use two class `NSUserNotification` and `NSUserNotificationCenter`. The first to create and manage the notification and the second to “display” it.

```swift
import Cocoa

// Create the notification and setup information

let notification = NSUserNotification()
notification.identifier = "unique-id"
notification.title = "Hello"
notification.subtitle = "How are you?"
notification.informativeText = "This is a test"
notification.soundName = NSUserNotificationDefaultSoundName
notification.contentImage = NSImage(contentsOfURL: NSURL(string: "https://placehold.it/300")!)

// Manually display the notification

let notificationCenter = NSUserNotificationCenter.defaultUserNotificationCenter()

notificationCenter.deliverNotification(notification)
```

{% asset user-notifications-simple.png %}

## Schedule

Now, let’s say we want to schedule the display to be **10 seconds** later. We just need to add a property:

```swift
notification.deliveryDate = NSDate(timeIntervalSinceNow: 10)
```

And we need to modify the display method:

```swift
notificationCenter.scheduleNotification(notification)
```

However `scheduleNotification` does not really display the notification, the *Notification Center* decides if it should be displayed or not. Usually, the notification it’s not display if the app is already in focus. We’ll see later how to override that behavior.

To repeat a notification, like *Reminders*, it is also very easy. Let’s say I want to repeat every day:

```swift
let repeatInt = NSDateComponents()
repeatInt.day = 1
notification.deliveryRepeatInterval = repeatInt
```

*Note: the minimum time interval allowed is \**one minute**, else you’ll have a runtime error.*

### Button

You can add a reply field with a custom placeholder:

```swift
notification.hasReplyButton = true
notification.responsePlaceholder = "Type you reply here"
```

{% asset user-notifications-reply-all.png %}

### Handle response

To be able to retrieve the content of the reply field, we need to implement `NSUserNotificationCenterDelegate` protocol.

AppDelegate’s `applicationDidFinishLaunching` method is a good candidate for of delegate.

```swift
NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
```

After the user validated his response, the Notification Center will call `userNotificationCenter:didActivateNotification`, we just need to check the activation type:

```swift   
func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
    switch (notification.activationType) {
        case .Replied:
            guard let res = notification.response else { return }
            print("User replied: \(res.string)")
        default:
            break;
    }
}
```

That’s all!

See [ActivationType reference](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSUserNotification_Class/#//apple_ref/c/tdef/NSUserNotificationActivationType) for further value.

Like I said, it’s possible to override `scheduleNotification` behavior. You can force a notification to be displayed, thanks to `userNotificationCenter:shouldPresentNotification`.

```swift
func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
    return true
}
```

# Alerts

On the contrary of banners, alerts aren’t dismissed automatically.

To modify the notification style we need to add a property into `Info.plist`. Set `NSUserNotificationAlertStyle` as key with `alert` string value.

{% asset user-notifications-infoplist.png %}

Same as banners, you need to configure `hasReplyButton` and `responsePlaceholder` properties, to enable reply, else you’ll have default buttons. You can configure them to display what you want instead of *Show/Close*:

```swift
notification.hasActionButton = true
notification.otherButtonTitle = "Marco"
notification.actionButtonTitle = "Polo"
```

{% asset user-notifications-buttons.png %}

### Additional actions

It’s sometimes useful to offer multiple actions to users, directly from the notification, as a non-breaking workflow.

It’s not possible to have both reply field and additional actions. Reply will be shown if hasActionButton and hasReplyButton are both true.
{: .notice--info}

Additional actions are an array of `NSUserNotificationAction`:

```swift
var actions = [NSUserNotificationAction]()

let action1 = NSUserNotificationAction(identifier: "action1", title: "Action 1")
let action2 = NSUserNotificationAction(identifier: "action2", title: "Action 2")
let action3 = NSUserNotificationAction(identifier: "action3", title: "Action 3")

actions.append(action1)
actions.append(action2)
actions.append(action3)
        
notification.additionalActions = actions
```

{% asset user-notifications-actions.png %}

Currently, you need to **hold-click** the action button to display the additional actions and there is no little arrow on hover.

There is a workaround, to display like the *Reminders* app. But it’s ugly. It uses the **private** API so I highly recommend using with **precautions** especially in production application:
{: .notice--danger}

```swift
// WARNING, private API
notification.setValue(true, forKey: "_alwaysShowAlternateActionMenu")
```

{% asset user-notifications-workaround.png %}

You don’t longer have access to the action button with this workaround.

### Handle actions

Go back to `userNotificationCenter:didActivateNotification` and add these switch cases:

```swift
case .AdditionalActionClicked:
    guard let choosen = notification.additionalActivationAction, let title = choosen.title else { return }
    print("Action: \(title)")
case .ActionButtonClicked:
    print("Action button (Polo)")
case .ContentsClicked:
    print("Contents clicked")
```

# References

[https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSUserNotification_Class/](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSUserNotification_Class/)

[https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSUserNotificationCenter_Class/](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSUserNotificationCenter_Class/)

[https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSUserNotificationCenterDelegate_Protocol/](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSUserNotificationCenterDelegate_Protocol/)

[https://developer.apple.com/reference/foundation/nsusernotificationaction](https://developer.apple.com/reference/foundation/nsusernotificationaction)