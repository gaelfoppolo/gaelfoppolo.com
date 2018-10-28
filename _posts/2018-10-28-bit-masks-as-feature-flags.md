---
title: Bit masks as feature flags
categories: [ios]
excerpt: Here comes that time where masks are dusted off and brought out of the cupboard within which they have lain dormant for the past years. Isn't it the best period to talk about bit masks? 👺
---

Like many languages, Swift offers enumeration as first-class type. An enumeration defines a new group type of related values and allows us to work with those values in a type-safe way.

Among other things, enumerations are great to represent sets of options.

Let's take as example `UIViewAnimationOptions`. This type describes the available options to animate an `UIView`. You can combine these options, sometimes it is even mandatory.

In Objective-C, this type is defined as an enumeration. To combine multiple options together, you need to "pipe" them, aka using a bitwise OR:

```objc
UIViewAnimationOptions options = UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseInOut;
```

However, in Swift this type is defined and used differently: it is a `struct` conforming to the `OptionSet` protocol, and you use it like a set.

```swift
var options: UIView.AnimationOptions = [.repeat, .autoreverse, .curveEaseInOut]
```

## OptionSet

Enumerations have one problem, you can only set one option at the time. This is the soul of an enumeration. The Objective-C version of `UIViewAnimationOptions` is expressed in a hacky-way, hijacking the prime goal of the enumeration.

OptionSet was designed to solve this very problem: a set where you can *set* multiple options at the same time. Under the hood, OptionSet is *represented* as a bit field but *presented* as an operation set. Basically, OptionSet enables us to represent bitset types and perform easy bit masks and bitwise operations.

Conforming to OptionSet only requires to provide a `rawValue` property of **integer** type. This type will be used as the underlying storage for the bit field. Indeed, integers are stored as a series of bits in memory. The size of the integer type will determine the maximum number of options you can define for your set to work *accurately*.  

```swift
struct MyOptionSet: OptionSet {
    let rawValue: Int8
}
```

MyOptionSet uses `Int8` and will be able to represent up to 8 options *accurately*.

Note that each option represents a single bit of the `rawValue`. In order to represent these options correctly, we need to assign ascending powers of two to each option: 1, 2, 4, 8, 16, etc.

```swift
struct MyOptionSet: OptionSet {
    let rawValue: Int8
	
    static let option1 = MyOptionSet(rawValue: 1)
    static let option2 = MyOptionSet(rawValue: 2)
    static let option3 = MyOptionSet(rawValue: 4)
    static let option4 = MyOptionSet(rawValue: 8)
}
```

Now when combining two or more options (aka bit mask), there is no overlapping.

```swift
var options: MyOptionSet = [.option1, .option2] // 1 + 2 = 3
var anotherOptions: MyOptionSet = [.option1, .option2, .option3] // 1 + 2 + 4 = 7
var oddOptions: MyOptionSet = [.option1, .option3] // 1 + 4 = 5
```

OptionSet conforms to `SetAlgebra`, meaning you can manipulate it with multiple mathematical set operations: insert, remove, contains, intersection, etc.

## Bitwise left shifting

Integers are stored as bitfield. For example, using `Int8`, the value 6 (decimal) or 0x40 (hexadecimal) is stored like so:

```sh
00000110
```

A common bitwise operation is left shifting, noted `<<`. 

Left shifting shift the digits to the left according to the offset specified and fill the right empty spaces with zeros. Shifting this bit pattern to the left from one position (`6 << 1`) result in the number 12 (decimal):

```sh
00001100
```

Left shifting is equivalent to multiplication by powers of 2, regarding the offset. Shifting 6 from three positions (`6 << 3`) result in the number 48 ($6 \times 2^3$).

Using left shifting is pretty common good practice when describing OptionSet options ; just increase the shifting position and let the math do the rest.

```swift
static let option1 = MyOptionSet(rawValue: 1 << 0) // 1
static let option2 = MyOptionSet(rawValue: 1 << 1) // 2
```

## Feature flags

Let's look at a worked example. Feature flags is a technique allowing to modify system behavior without changing code. They can help us to deliver new functionality to users rapidly and safely.

For example, you could be in the process of rewriting a part of your app to improve its efficiency. This work will take some time, probably multiple weeks, but you don't want to impact your team, that will continue to work on other parts of the app. Branching is a no go, thanks to previous experiences of merging long-lived branches. Instead, the people working on that rewrite will use a specific feature flag to use the new implementation, while the other will continue to use the current one as usual.

Canary deployment is another great benefit of feature flags. Say your rewrite is ready and you would like to test it in real conditions. However, you don't want to deliver it to all of your users, and go back to the old implementation in case there is something wrong. With feature flags, you can only activate the new implementation for a small percentage of users. 

Since WWDC 2017, Apple introduced "phased releases", the ability to gradually release new versions of an application. However, with your own implementation of feature flags you get fine grained control over who is exposed to which feature and when. This is also useful when rolling out time based functionalities and need absolute control.

Feature flags can be implemented in many ways, but all of them will introduce additional complexity in your system. Our goal is to constrain this complexity by using a smart implementation.

Let's see how `OptionSet` can help us reduce this complexity.

```swift
struct FeatureFlags: OptionSet {

    let rawValue: Int

    static let feature1 = FeatureFlags(rawValue: 1 << 0) // 1
    static let feature2 = FeatureFlags(rawValue: 1 << 1) // 2
    static let feature3 = FeatureFlags(rawValue: 1 << 2) // 4
    static let feature4 = FeatureFlags(rawValue: 1 << 3) // 8
    static let feature5 = FeatureFlags(rawValue: 1 << 4) // 16
    static let feature6 = FeatureFlags(rawValue: 1 << 5) // 32
    static let feature7 = FeatureFlags(rawValue: 1 << 6) // 64

}
```

Fundamentally, that's all what we need.

Now, let's say we want a particular combination of these flags, a feature groups. We can use the array notation like `UIView.AnimationOptions` or we can take advantage of the capabilities offer by OptionSet. We can add the following to our `FeatureFlags` type, and use it like the other option:

```swift
static let evenFeature: FeatureFlags = [.feature2, .feature4, .feature6] // 2 + 8 + 32 = 42
```

Usually, you retrieve these flags from an API, where each flag is represented by a boolean value. This is where the magic of`OptionSet` begin : instead of list of boolean flags, you can use a single integer value representing all your flags!

```swift
var options = FeatureFlags(rawValue: 97)
```

The variable `options` now contains `feature1` , `feature6` and `feature7` ($1+32+64 = 97$). 

You even can have several `FeatureFlags`: a global one, one for each of your key functionalities, one specific to your user, etc. And of course, combine them!

## One More Thing

OptionSet isn't a collection. You can't count them or iterate over them. However, since we only define them with integer values, we can improve the protocol to help us work with them.

```swift
protocol OptionSetCountable: OptionSet {
    static var count: Int { get }
}

extension OptionSetCountable where Self.RawValue == Int {
    static var all: Self {
        let allRaw: Int = Array(0 ..< self.count).reduce(0) { $0 + 1 << $1 }
        return Self(rawValue: allRaw)
    }

    var members: [Self] {
        return Array(0 ..< type(of: self).count).compactMap { self.rawValue & (1 << $0) != 0 ? Self(rawValue: 1 << $0) : nil }
    }
}
```

`all` produces an instance of your type with all options, while `members` computes the list of all options of a particular instance, practical to iterate.

Let's update the conformance and add the new property to our type. We also add conformance to `CustomStringConvertible` for debug purpose.

```swift
struct FeatureFlags: OptionSetCountable {

    let rawValue: Int
    static let count = 7

    static let feature1 = FeatureFlags(rawValue: 1 << 0) // 1
    static let feature2 = FeatureFlags(rawValue: 1 << 1) // 2
    static let feature3 = FeatureFlags(rawValue: 1 << 2) // 4
    static let feature4 = FeatureFlags(rawValue: 1 << 3) // 8
    static let feature5 = FeatureFlags(rawValue: 1 << 4) // 16
    static let feature6 = FeatureFlags(rawValue: 1 << 5) // 32
    static let feature7 = FeatureFlags(rawValue: 1 << 6) // 64

}

extension FeatureFlags: CustomStringConvertible {

    var description: String {
        get {
            switch self {
            case .feature1:
                return "Feature 1"
            case .feature2:
                return "Feature 2"
            case .feature3:
                return "Feature 3"
            case .feature4:
                return "Feature 4"
            case .feature5:
                return "Feature 5"
            case .feature6:
                return "Feature 6"
            case .feature7:
                return "Feature 7"
            default:
                return ""
            }
        }
    }
}

```

You can try it with a set of examples:

```swift
let fullSet = FeatureFlags.all
let option = FeatureFlags(rawValue: 97)
let option2 = FeatureFlags(arrayLiteral: [.feature6, .feature7])
let options = [fullSet, option, option2]

for option in options {
    print(option.members)
}

let max = Int(pow(Double(2), Double(FeatureFlags.count)))
for _ in 0...10 {
    let random = Int.random(in: 1 ..< max)
    print(FeatureFlags(rawValue: random).members)
}
```

And a set of results:

```sh
[Feature 1, Feature 2, Feature 3, Feature 4, Feature 5, Feature 6, Feature 7] // fullSet
[Feature 1, Feature 6, Feature 7] // option
[Feature 6, Feature 7] // option 2

// random option

[Feature 2, Feature 5, Feature 6]
[Feature 3, Feature 7]
[Feature 1, Feature 4, Feature 5, Feature 6]
[Feature 3, Feature 5]
[Feature 2, Feature 5]
[Feature 3, Feature 5]
[Feature 2, Feature 3]
[Feature 4, Feature 7]
[Feature 3, Feature 5, Feature 7]
[Feature 1, Feature 2, Feature 4]
[Feature 4, Feature 6, Feature 7]
```