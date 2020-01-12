---
title: Handling the @unknown
categories:
- swift
date: 2020-01-12 20:25 +0100
---
This week, I've been working on improving the code coverage of an iOS application.
One of the scenarios I've been testing involved an enum, with a handful of cases.
Eager to maximise my coverage, I created several test functions to cover them all.
Unfortunately, during this process, I've made a mistake, leading to a crash of my application when running these new tests.

{% error %}
Fatal error: unexpected enum case 'MyEnum(rawValue: -2)
{% enderror %}

Luckily, this is a happy mistake, which prevented me hours of research.
Let's see what happened.

# The Mistake

My enum is defined quite simply, this is a C-style enum with three cases.

{% highlight objc %}
typedef NS_ENUM(NSInteger, MyEnum) {
 MyEnumOne = 1,
 MyEnumTwo = 2,
 MyEnumThree = 3,
};
{% endhighlight %}

At some point in my scenario, I instantiate my enum using `init(rawValue:)` and I switch over it, handling each of the three cases.

When writing my tests, I made a typo leading to an instantiation of `MyEnum` with the value of *-2*. This worked.
After some digging, I understood why. Formally, Objective-C allows storing any value in an enumeration as long as it fits in the underlying type. Since *-2* is an integer, it works here.

The crash happens when I switch over this value. Since I handle only the "declared" cases of the enum, the program traps at runtime. My non-frozen C-style enum is the culprit.

# The Solutions

My project still uses Swift 4, an element I forgot to mention earlier.
This is why no diagnostic is produced by the compiler, either warning or error.

To handle this, we have three solutions.

## Catch them all

To catch this, we can include a safety net, a way to safely handle unexpected cases, for example, future ones.
Since my switch is exhaustive, this solution takes the form of adding a `default` case. And this works.
However doing this, we produced another unwanted side effect. Imagine if I choose to add another case to my enum, `MyEnumFour(4)`. The compiler will no longer produce a diagnostic error, stating that this new case is not explicitly handled in the switch, since the `default` already handles it.

To remedy that, we can use `@unknown default`. This solution combines a catch-all and also alert us if all known elements of the enum have not already been matched.

## Froze them all

Enums come in two forms: frozen (`NS_CLOSED_ENUM`) and non-frozen (`NS_ENUM`).
Another solution is then to choose using a frozen enum. The compiler will recognize this and will not ask to implement a `default` case.

But there is a _catch_. 

You are making a promise. The promise your enum will never change in the future.
You still _can_ add new cases to a frozen enum, but you are breaking that promise.
And the consumers of your enum will remember that, believe me.

Of course, you can only choose this solution if you're in control of the enum.
For example, you can't choose this solution for an enum of Apple.

## Update them all

Since Swift 5 ([SE-0192](https://github.com/apple/swift-evolution/blob/master/proposals/0192-non-exhaustive-enums.md)), the diagnostic take the form of a warning.

Where this diagnostic will be raised, you can add `@unknown default` to handle the unexpected cases.

Be advised, no diagnostic will be produced if your enum already has a `default` case.