---
title: Security Code AutoFill
categories: [ios, security]
---

OTP are becoming a security requirement nowadays. There are an essential part of our usage flow. We want to perform a sensitive action, we need to verify and confirm it with a security code.

Unfortunately the flow can be very tedious. The code is requested and received. Either you have a blasting memory and can type the code during the short amount of time of the notification. Or you switch to the Messages app and copy the code, and again back in the app.

{% include 
    image.html 
    src="security-code-autofill-before.png"
    alt="Before Security Code AutoFill"
    caption="Before Security Code AutoFill"
%}

With iOS 12, you can ease this process for your user, by providing an in-app AutoFill option, directly to the QuickType bar. Users can fill them with one tap. With zero effort. 

{% include 
    image.html 
    src="security-code-autofill-now.png"
    alt="With Security Code AutoFill"
    caption="With Security Code AutoFill"
    style="half"
%}

# Show me the code

{% highlight swift %}
let otpTextField = UITextField() 
otpTextField.textContentType = .oneTimeCode
{% endhighlight %}

That's it **and this is not mandatory.** 

As of iOS 12, all `UITextField` can display this AutoFill option by default, when the system detects a security code. 

However, if your view displays several text fields, using this specific [`UITextContentType`](https://developer.apple.com/documentation/uikit/uitextcontenttype/2980930-onetimecode) will help the system, by providing an indication, a hint. iOS will then only display the AutoFill option in the specified text field tagged with security code content type.

# Limitations

There are a couple of things to keep in mind, if you want to support this:

- iOS **12.0**+
- **System keyboard** required. If you use a third-party keyboard, like SwiftKey, iOS will switch back to the system keyboard when a code is detected.

- iOS will show the code for up to **three** minutes after it has been received.

- iOS will only show a code if one is detected (meaning **parsed**). To ensure yours is supported, verify the message contains an underlined security code and tap on the code. If a Copy Code option appears, the system has recognized the code.

# Bonus

This type of code is usually used for financial transaction. If your message contains an amount of money and, if detected, QuickType bar will also display this information.

{% include 
    image.html 
    src="security-code-autofill-amount.png"
    alt="QuickType bar with an amount of money"
    caption="QuickType bar with an amount of money"
    style="half"
%}

This is a simple addition, but very useful for users, as it helps them identify security codes and confirm their validity.

*[OTP]: One Time Password