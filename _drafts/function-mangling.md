---
title: Function mangling
categories: [swift]

---

During our iOS debugging sessions, we have to search though infinite stacktraces, hopefully to find some evidences. We all do this. But on some occasions, we may stumble upon some cryptic strings like, looking like this.

```
_TFC16MyProjectExample7MyClass10myFunctionfS0_FT1xSi_Si
```

This kind of garbisch is the result of the object code, and is called **name mangling**. The good news is, Xcode embed a tool to retrieve the original form. But first, let's dive a little into the concept.

## A unique symbol

In computer programming, when we wish to compile our program, the compiler goes by a numerous steps before producing a working executable file. The last step involves the **linker**, which will try to resolve all the references of the entities previously compiled (object code), and merge them into your executable file.

// human have unique name

// when two people have the same name, and someone called them, how can we know which one

Unfortunately, nowadays, our programming languages evolved and supported a ton of great features such as function overloading or namespacing. But these two features make the life of the compiler impossible. How can he knows which implementation link at compile time?

Hopefully, this is where **name mangling** solves this problem. With this technique, the compiler encodes additional information on the function (think metadata), creating a unique name for it.

// dSYM?

## What are the rules?

Let's take a quick closer look on how this works for Swift. If you ever wrote an parser, it will be easy. You just have to know the rules. Let's break the components.

```
_TFC16MyProjectExample7MyClass10myFunctionfS0_FT1xSi_Si
```

| Component            | Meaning                                                      |
| -------------------- | ------------------------------------------------------------ |
| `_T`                 | The start of a Swift symbol.                                 |
| `F`                  | The symbol type is a function.                               |
| `C`                  | The function happens to be inside a class.                   |
| `16MyProjectExample` | The name of the module containing the class. <br />The number at the beggining is the length of the following string. |
| `7MyClass`           | The name of the class. <br />The number at the beggining is the length of the following string. |
| `10myFunction`       | The name of the function. <br />The number at the beggining is the length of the following string. |
| `f`                  | This tell the parser we are entering the function.           |
| `S0_`                | The type of the first parameter, the class instance (`MyClass`). |
| `F`                  | This tell the parser we are entering the parameters list.    |
| `T`                  | This tell the parser we are entering a parameter tuple (name, type). |
| `1x`                 | The name of the parameter. <br />The number at the beggining is the length of the following string. |
| `Si`                 | The type of the parameter, `Swift.Int`.                      |
| `_Si`                | The return type of the function `Swift.Int`.                 |

All the rules are [on the Swift repo](https://github.com/apple/swift/blob/master/lib/Demangling/Demangler.cpp), if you want to know more.

## A new tool

The good news is, you can easily *unmangle* your string using a simple command, included in every Xcode:

```shell
$ xcrun swift-demangle -compact _TFC16MyProjectExample7MyClass10myFunctionfS0_FT1xSi_Si
MyProjectExample.MyClass.myFunction(MyProjectExample.MyClass) -> (x: Swift.Int) -> Swift.Int
```

or you can use the [online version](https://www.swiftdemangler.com)!