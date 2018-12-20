---
title: Security Code AutoFill
categories: [ios, security]

---

OTP are becoming a security requirement nowadays. There are an essential part of our usage flow. We want to perform a sensitive action, we need to verify and confirm it with a security code.

Unfortunately the flow can be very tedious. The code is requested and received. Either you have a blasting memory and can type the code during the short amount of time of the notification. Or you switch to the Messages app and copy the code, and again back in the app.

{% asset security-code-autofill-before.png %}

With iOS 12, you can ease this process for your user, by providing an in-app AutoFill option, directly to the QuickType bar. Users can fill them with one tap. With zero effort. 

{% asset security-code-autofill-now.png %}

## Show me the code

```swift
let otpTextField = UITextField() 
otpTextField.textContentType = .oneTimeCode
```

That's it. Reference: [UITextContentType.oneTimeCode](https://developer.apple.com/documentation/uikit/uitextcontenttype/2980930-onetimecode).

**This is not mandatory.**  

As of iOS 12, all `UITextField` can display this AutoFill option by default, when the system detects a security code. 

However, if your view displays several text fields, using this specific `UITextContentType` will help the system, by providing an indication, a hint. iOS will then only display the AutoFill option in the specified text field tagged with security code content type.

## Limitations

There are a couple of things to keep in mind, if you want to support this:

- iOS **12.0**+

- **System keyboard** required. 

  If you use a third-party keyboard, like SwiftKey, iOS will switch back to the system keyboard when a code is detected.

- iOS will show the code for up to **three** minutes after it has been received.

- iOS will only show a code if one is detected (**parsed**). 

  To ensure yours is supported, verify the message contains an underlined security code and tap on the 
  code. If a Copy Code option appears, the system has recognized the code.

## Bonus

This type of code is usually used for financial transaction. If your message contains an amount of money and, if detected, QuickType bar will also display this information.

{% asset security-code-autofill-amount.png %}

This is a simple addition, but very useful for users, as it helps them identify security codes and confirm their validity.

## Reference

[WWDC 2018 — Session 204](https://developer.apple.com/videos/play/wwdc2018/204/)

[Apple Documentation — About the Password AutoFill Workflow](https://developer.apple.com/documentation/security/password_autofill/about_the_password_autofill_workflow)

[When Convenience Creates Risk: Taking a Deeper Look at Security Code AutoFill on iOS 12 and macOS Mojave](https://www.benthamsgaze.org/2018/10/17/when-convenience-creates-risk-taking-a-deeper-look-at-security-code-autofill-on-ios-12-and-macos-mojave/)

*[OTP]: One Time Password