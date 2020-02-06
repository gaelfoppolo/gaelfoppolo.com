---
title: Simulating remote push notifications
categories:
- xcode, ios, tool
date: 2020-02-07 07:00 +0100
---
Currently, when I want to test a part of an app involving a remote notification, I only have one choice: using a real device and the Apple Push Notification service (APNs). To send a notification, we need an *APNs device token*, which is a globally unique token that identifies a device to APNs.

And this is painful for several reasons: we need entitlement, certificate (.p12) and to rely on APNs.
You can't test locally, we need Internet access.

I used to work with [NWPusher](https://github.com/noodlewerk/NWPusher) or [lola](https://github.com/industrialbinaries/lola), small tools, to achieve that purpose.

And I still will use them, but now we have a better one.

Starting Xcode 11.4, it is now possible to simulate remote push notifications directly within the Simulator.
All the pain points listed above are now gone as it happens locally.

The best way is to use the `simctl` command-line tool, that provides the interface to use Simulator programmatically.

{% highlight sh %}
xcrun simctl push <device> [<bundle identifier>] (<payload json file> | -)
{% endhighlight %}

# Device

This is the device UUID on which we will send the notification.
You can either specify the UUID or `booted`.
To find the UUID of your booted Simulator, `xcrun simctl list | egrep 'Booted'`.

# Bundle identifier

This is the `APP_PRODUCT_BUNDLE_IDENTIFIER.`
You can specify the bundle identifier as an argument.

# Payload

This is the payload of the notification. Please see [Creating the Remote Notification Payload](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html) for further documentation.

{% highlight json %}
{
    "aps" : {
        "alert" : {
            "title": "My title",
            "body" : "This is a test",
        }
    }
}
{% endhighlight %}

You can either specify the path of the file as the last argument or use `-` for standard input.

# Putting them together

{% highlight sh %}
xcrun simctl push booted com.gaelfoppolo.SimulatingRemoteNotifications payload.json
{% endhighlight %}

We can also omit the bundle identifier by specifying it in the payload under the `Simulator Target Bundle` key.
{% highlight json %}
{
    "aps" : {
        "alert" : {
            "title": "My title",
            "body" : "This is a test",
        }
    },
    "Simulator Target Bundle": "com.gaelfoppolo.SimulatingRemoteNotifications"
}
{% endhighlight %}
{% highlight sh %}
xcrun simctl push booted payload.json
{% endhighlight %}

{% include 
 image.html 
 src="simulating-remote-notifications.gif"
 alt="Simulate remote push notifications"
 caption="Simulate remote push notifications"
%}