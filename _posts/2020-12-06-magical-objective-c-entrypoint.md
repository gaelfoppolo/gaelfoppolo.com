---
title: Magical Objective-C entrypoint
categories:
- swift
- ios
- objective-c
date: 2020-12-06 07:00 +0100
---

Last week, I had to upgrade an old project from Swift 3. The Xcode migrator tool upgraded automatically all the codebase, without any issue. Yet, when running the app, I noticed a small problem: the layout of a particular screen was completely screwed. 

The screen was a simple `UICollectionView` and was displaying items correctly before the migration. The issue was obviously from the Swift 3 to 4 migration. But no code related to that screen had been translated. 

While trying to understand what could happen, I began to read about the changes between Swift 3 and 4, hoping that it could point me in the right direction. One aspect was the deprecation of `@objc` inference and as you might guess, this was the starting point of the issue.

## Swift @objc inference

To improve Objective-C interoperability, the Swift compiler conveniently infers for you a lot of `@objc` making your Swift classes, methods and properties available to Objective-C. **Even when you don't want it**. This was true up until Swift 3. Starting Swift 4, the compiler team decided to limit this behaviour and infer only for a handful of cases, for several reasons.

When upgrading to Swift 4, Xcode warns you about this evolution and lets you choose between two options: minimize the inference or match Swift 3 behaviour. The former is recommended and was used in my case.

Back to our issue. Looking closely to the Issue Navigator, I noticed a couple of runtime warnings.

```
implicit Objective-C entrypoint -[MyApp.MyCollectionViewController collectionView:layout:sizeForItemAtIndexPath:] is deprecated and will be removed in Swift 4
```

So this had to do something with the inference. By using a breakpoint, I saw that `collectionView:layout:sizeForItemAtIndexPath:` was never called after the migration.

## Debugging implicit Objective-C entrypoint

Fortunately, the compiler team thought about that and provided an environment variable to set in your scheme to help you identify the issue. `SWIFT_DEBUG_IMPLICIT_OBJC_ENTRYPOINT` can take three values:

- 1: will log the same message as above in the console
- 2: same as 1 + will provide a backtrace
- 3: same as 2 + will crash the application

In my case, the value 2 is enough to understand the issue, but it is recommended to use the latest value after a migration while running tests.

Going back to the guilty class, `MyCollectionViewController`. The Swift Language Runtime tells me that the method `sizeForItemAtIndexPath` is found but cannot be called because it is not exposed to Objective-C. 

I could add an `@objc` to the method and call it a day, but this does not feel right.

## A deeper issue

The first thing to fix is the name. **sizeForItemAtIndexPath** is the old Swift 3 name, so I renamed it to **sizeForItemAt**.

**sizeForItemAt** is part of `UICollectionViewDelegateFlowLayout` and `MyCollectionViewController` uses a custom flow layout but does not declare its conformance to the flow layout delegate protocol. Since this protocol does not require anything (all method are optional), there are no compiler error or warning.

This was the root issue. A missing protocol conformance to `UICollectionViewDelegateFlowLayout`. Using the Swift 3 compiler, the method was automatically exposed and so found at runtime. Using the Swift 4 compiler, the method is not exposed and it's like we did implement it at all.