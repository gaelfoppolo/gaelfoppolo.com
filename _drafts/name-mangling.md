---
title: Name mangling
categories: [swift]

---

During our iOS debugging sessions, we have to search though infinite stack traces, hopefully to find some evidence. We all do this. But on some occasions, we may stumble upon some cryptic strings like, looking like this.

```
_TFC16MyProjectExample7MyClass10myFunctionfS0_FT1xSi_Si
```

This is the result of the object code, and is called **name mangling**. The good news is, Xcode embed a tool to retrieve the original form. But first, let's dive a little into the concept.

## A unique symbol

In computer programming, when we wish to compile our program, the compiler goes by a numerous steps before producing a working executable file. The last step involves the **linker**, which will try to resolve all the references of the entities previously compiled (object code), and merge them into your executable file.

Unfortunately, nowadays, our programming languages evolved and supported a ton of great features such as function overloading or namespacing. But these two features make the life of the compiler impossible. How can he know which implementation link at compile time?

We humans do not even have unique name. Odds are there at least one other person who has the same name as you on this Earth. If you have a common name, the odds are skyrocketing. How can we differentiate you from the others *you*? With others contextual information, such as current location, birth place, etc.

Same applies in programming. **Name mangling** solves the problem. With this technique, the compiler encodes additional information on the function (think metadata), creating a unique name for it.

For example, dSYM files contain theses *mangled* symbols.

## What are the rules?

Let's take a quick closer look on how this works for Swift. If you ever wrote a parser, it will be easy. You just have to know the rules.

```
_TFC16MyProjectExample7MyClass10myFunctionfS0_FT1xSi_Si
```

| Component            | Meaning                                                      |
| -------------------- | ------------------------------------------------------------ |
| `_T`                 | The start of a Swift symbol.                                 |
| `F`                  | The symbol type is a function.                               |
| `C`                  | The function happens to be inside a class.                   |
| `16MyProjectExample` | The name of the module containing the class. <br />The number at the beginning is the length of the following string. |
| `7MyClass`           | The name of the class. <br />The number at the beginning is the length of the following string. |
| `10myFunction`       | The name of the function. <br />The number at the beginning is the length of the following string. |
| `f`                  | This tells the parser we are entering the function.          |
| `S0_`                | The type of the first parameter, the class instance (`MyClass`). |
| `F`                  | This tells the parser we are entering the parameters list.   |
| `T`                  | This tells the parser we are entering a parameter tuple (name, type). |
| `1x`                 | The name of the parameter. <br />The number at the beginning is the length of the following string. |
| `Si`                 | The type of the parameter, `Swift.Int`.                      |
| `_Si`                | The return type of the function `Swift.Int`.                 |

All the rules are [on the Swift repo](https://github.com/apple/swift/blob/master/lib/Demangling/Demangler.cpp), if you want to keep having fun.

## A new tool

The good news is, you can easily *unmangle* your string using a simple command, included in every Xcode:

```shell
$ xcrun swift-demangle -compact _TFC16MyProjectExample7MyClass10myFunctionfS0_FT1xSi_Si
MyProjectExample.MyClass.myFunction(MyProjectExample.MyClass) -> (x: Swift.Int) -> Swift.Int
```

or you can use the [online demangler](https://www.swiftdemangler.com)!