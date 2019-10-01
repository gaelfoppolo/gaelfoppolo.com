---
title: 'The secret keyword behind higher-order functions: rethrows'
categories: [swift]
---

Higher-order functions are functions that take one or more functions as arguments. They are the cornerstone of functional programming, allowing us to write operators. 

Let's take an example.

{% highlight swift %}
func performArithmeticalOperation(_ x: Int, operation: (Int) -> Int) -> Int {
    return operation(x)
}

func double(_ x: Int) -> Int {
    return x * 2
}

performArithmeticOperation(4, operation: double) // -> 8
// as trailing closure
performArithmeticOperation(4) { $0 / 2 } // -> 2
{% endhighlight %}

A function that can perform any type of arithmetical operation on `Int`. 

Let's assume an operator function might raise an error. 

{% highlight swift %}
enum RandomError: Error {
    case myError
}

func random(_ x: Int) throws -> Int {
    if Bool.random() {
        return x * 2
    } else {
        throw RandomError.myError
    }
}
{% endhighlight %}

The compiler now rejects us when calling the high-order function, because the signature of `performArithmeticalOperation` does not match. We must update the `performArithmeticalOperation` signature and surround its calls with a do catch block. Yikes.

{% highlight swift %}
func performArithmeticalOperation(_ x: Int, operation: (Int) throws -> Int) throws -> Int {
    return try operation(x)
}

do {
    try performArithmeticalOperation(4, operation: random) // -> 8
} catch let error {
    dump(error) // -> myError
}
{% endhighlight %}

And we can't call `performArithmeticalOperation` using the `double` function without a do catch block, even if we know the function will never throw! A lot of unnecessary boilerplate code to come.

# Standard Library to the rescue!

Swift already embed quantity of higher-order functions and nevertheless we don't need to surround their call with a try catch block. How is that possible?

Looking closely to their signature, you can notice a strange keyword, `rethrows`.

{% highlight swift %}
func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] 
func flatMap<SegmentOfResult>(_ transform: (Element) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult : Sequence 
func compactMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] 
func filter(_ isIncluded: (Self.Element) throws -> Bool) rethrows -> [Self.Element] 
{% endhighlight %}

Only a quick section of our favorite book, The Swift Programming Language, mention it:

> A function or method can be declared with the `rethrows` keyword to indicate that it throws an error only if one of its function parameters throws an error.

Using this keyword, the compiler is now able to check at compile time if the function parameter will throw an error. `double` will never, so it does not need a try catch block. You'll even get a warning if you add it anyway.

{% highlight swift %}
func performArithmeticalOperation(_ x: Int, operation: (Int) throws -> Int) rethrows -> Int {
    return try operation(x)
}

performArithmeticalOperation(4, operation: double) // -> 8

do {
    try performArithmeticalOperation(4, operation: random) // -> 8
} catch let error {
    dump(error) // -> myError
}
{% endhighlight %}