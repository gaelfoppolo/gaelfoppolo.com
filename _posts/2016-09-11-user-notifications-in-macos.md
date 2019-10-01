---
title: User Notifications in macOS
date: 2016-09-11
categories: [macos]

---

**User Notifications** notify the user that something has changed in the application. Best known examples are the upcoming events in *Calendar* or the build status in *Xcode*.

[Notification Center](https://support.apple.com/en-us/HT204079) provides an overview of notifications from applications. As we will see, it’s very easy to integrate and display basic notifications in it.

Three display styles are available: None, Banner and Alert. By default, User Notifications are displayed using the **Banner** style.

{% warning %}
This article is no longer up-to-date as [`NSUserNotification`](https://developer.apple.com/documentation/foundation/nsusernotification) was deprecated in macOS 10.14 (Mojave). Please see [`UserNotifications`](https://developer.apple.com/documentation/usernotifications) for an up-to-date implementation.
{% endwarning %}

# Setup

We use two objects:

- `NSUserNotification`: to create and manage the notification
- `NSUserNotificationCenter`: to display the notification

{% highlight swift %}
import Cocoa

// Create the notification and setup information

let notification = NSUserNotification()
notification.identifier = UUID().uuidString
notification.title = "Hello"
notification.subtitle = "How are you?"
notification.informativeText = "This is a test"
notification.soundName = NSUserNotificationDefaultSoundName
notification.contentImage = NSImage(contentsOf: URL(string: "https://placehold.it/300")!)

// Delegate of the Notification Center

let notificationCenter = NSUserNotificationCenter.default

// Manually display the notification

notificationCenter.deliver(notification)
{% endhighlight %}

However this piece of code does not really display the notification, the *Notification Center* decides if it should be displayed or not. Usually, the notification it’s not display if the app is already in focus. 

To do that, we need to implement `NSUserNotificationCenterDelegate` protocol. `AppDelegate`’s `applicationDidFinishLaunching` method is a good candidate. You can force a notification to be displayed, thanks to `userNotificationCenter:shouldPresent`.

{% highlight swift %}

notificationCenter.delegate = self

[...]

func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
	return true
}
{% endhighlight %}

# Banner

Banners are simple notification view, dismissed after a few seconds.

{% include 
    image.html 
    src="user-notifications-simple-banner.png"
    alt="A simple banner notification"
    caption="A simple banner notification"
%}

# Alert

On the contrary of banners, alerts aren’t dismissed automatically.

{% include 
    image.html 
    src="user-notifications-simple-alert.png"
    alt="A simple alert notification"
    caption="A simple alert notification"
%}

To modify the notification style we need to add a property into `Info.plist`. Set `NSUserNotificationAlertStyle` as key with `alert` string value.

{% include 
    image.html 
    src="user-notifications-infoplist.png"
    alt="Info.plist"
    caption="Info.plist"
%}

# Adding an action

## Reply

We can add a reply field with a custom placeholder.

{% highlight swift %}
notification.hasReplyButton = true
notification.responsePlaceholder = "Type you reply here"
{% endhighlight %}

{% include 
    image.html 
    src="user-notifications-reply-hover.png"
    alt="A notification with reply — hover"
    caption="A notification with reply — hover"
%}

{% include 
    image.html 
    src="user-notifications-reply-focus.png"
    alt="A notification with reply — focus"
    caption="A notification with reply — focus"
%}

## Handle response

After the user validated his response, the Notification Center will call `userNotificationCenter:didActivate`, we just need to check the activation type:

{% highlight swift %}
func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
    switch (notification.activationType) {
        case .replied:
            guard let res = notification.response else { return }
            print("User replied: \(res.string)")
        default:
            break;
    }
}
{% endhighlight %}

{% info %}

See [ActivationType](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSUserNotification_Class/#//apple_ref/c/tdef/NSUserNotificationActivationType) for further reference.

{% endinfo %}

## Action

By default, on alert you’ll have default buttons, like displayed before. We can configure them, to match what you want.

{% highlight swift %}
notification.hasActionButton = true
notification.otherButtonTitle = "Marco"
notification.actionButtonTitle = "Polo"
{% endhighlight %}

{% include 
    image.html 
    src="user-notifications-action.png"
    alt="A notification with custom buttons title"
    caption="Custom buttons title"
%}

{% info %}
It’s not possible to have both reply field and action. Reply will be shown if `hasActionButton` and `hasReplyButton` are both true.
{% endinfo %}

## Additional actions

It’s sometimes useful to offer multiple actions to users, directly from the notification, as a non-breaking workflow.

Additional actions are an array of `NSUserNotificationAction`:

{% highlight swift %}
notification.additionalActions = [
    NSUserNotificationAction(identifier: "action1", title: "Action 1"),
    NSUserNotificationAction(identifier: "action2", title: "Action 2"),
    NSUserNotificationAction(identifier: "action3", title: "Action 3")
]
{% endhighlight %}

{% include 
    image.html 
    src="user-notifications-actions.png"
    alt="A notification with additional actions displayed"
    caption="Additional actions displayed"
%}

Currently, you need to **hold-click** the action button to display the additional actions and there is no little arrow on hover.

{% error %}
There is a workaround, to display like the *Reminders* app. But it’s ugly. It uses the **private** API so I highly recommend using with **precautions** especially in production application.

{% highlight swift %}
// WARNING, private API
notification.setValue(true, forKey: "_alwaysShowAlternateActionMenu")
{% endhighlight %}

{% include 
    image.html 
    src="user-notifications-workaround.png"
    alt="Arrow on hover"
    caption="Workaround: arrow on hover"
%}

You don’t longer have access to the action button with this workaround.
{% enderror %}

## Handle actions

Go back to `userNotificationCenter:didActivateNotification` and add these switch cases:

{% highlight swift %}
case .additionalActionClicked:
    guard let choosen = notification.additionalActivationAction, let title = choosen.title else { return }
    print("Action: \(title)")
case .actionButtonClicked:
    print("Action button (Polo)")
case .contentsClicked:
    print("Contents clicked")
{% endhighlight %}

# Scheduling

Finally, let’s say we want to schedule the display to be **10 seconds** later and then to repeat it every day.

{% highlight swift %}
notification.deliveryDate = NSDate(timeIntervalSinceNow: 10)

let repeatInt = NSDateComponents()
repeatInt.day = 1
notification.deliveryRepeatInterval = repeatInt

notificationCenter.schedule(notification)
{% endhighlight %}

Notice, that instead of `deliver`, we used `schedule` function.

{% info %}

The minimum time interval allowed is one minute, else you’ll have a runtime error.

{% endinfo %}
