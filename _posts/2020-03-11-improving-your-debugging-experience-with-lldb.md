---
title: Improving your debugging experience with LLDB
categories:
- lldb
- xcode
- ios
- debug
date: 2020-03-11 07:00 +0100
---
LLDB, which stands for Low Level Debugger, is the default debugger in Xcode and a powerful ally when it comes to inspecting and analyzing the program state in a controlled environment. Engineers can better understand how the program behaves, isolate and reproduce troublesome pathways, make assumptions and apply hypothesis. All of this, on-the-fly, without the burden of having to recompile.

This last point is extremely important for large codebases. When the program takes several minutes to compile, even for small changes, one can quickly lose patience.

Because Xcode provides a great abstraction for the most used LLDB commands (adding a breakpoint, stepping over calls, ect.), most of the time, only a small fraction of its abilities is in fact, known and used.

Let's take a look at some basic commands, which will give some super debugging powers.

# Evaluating an expression

The most used feature of LLDB is the evaluation of expressions on the current thread.

Using the `expression` command, you can query or change the state of a property to alter the final output of the program.

The derivated forms of this command are well known. 
- `expr` and `e` are aliases for `expression`
- `p`, an abbreviation for `expression -`
- `po`, an abbreviation for `expression -O  --`

``` shell
(lldb) expression -- print(myVar)
(lldb) expr -- debugPrint(myVar)
(lldb) e -- myVar = "myString"
(lldb) p -- myVar = "anotherString"
(lldb) po -- myVar
```

# Inspecting the state

The second most used feature of LLDB is the inspection of data on the current stack frame.
Using the `frame` command, you can query the state of a property in the call stack.
I will focus on the subcommand `frame variable`, which show variables for the current stack frame.

Several derivated of this command are also well known.
- the standard `var` and `v`, abbreviations for `frame variable`
- `vo`, an abbreviation for `frame variable -O`.

``` shell
(lldb) frame variable myVar
(lldb) var myVar
(lldb) v myVar
(lldb) vo myVar
```

Note that using `frame variable` (or its other forms) is more efficient than `expression` to perform a simple inspection, since it uses memory reads directly, rather than evaluating an expression. When using `po`, you are evaluating the object as an expression. Be aware of the potential side effects.

# Controlling the execution flow

Another crucial aspect of debugging is the ability to control the execution flow of the program.
Using the `thread` command, you can achieve almost any move you want.

As said earlier, Xcode already provides some graphical abstraction for some of its subcommands (`next`, `step`, ect.), I will focus on one not widely known.

`thread jump` set the program counter to a new address. With this command, you can skip a section of the program, which can be interesting to access a particular point of the program.

As usual, some derivated forms of this command exist; `jump` or `j` is easier to remember and use.

Let's assume our program paused and we want to skip two lines ahead.

``` shell
(lldb) thread jump --by 2
(lldb) jump -b 2
(lldb) j +2
```

By doing this, the program may enter in an unstable, potentially unknown, state, since this alters the correct execution flow of the program. Be aware of the consequences.

# Breaking and watching

To control the execution flow, engineers often need to first interrupt the execution, to better understand it. That is what breakpoints are meant for.

LLDB provides numerous subcommands and options to list, set, modify or delete breakpoints. 

One is yet poorly known, the ability to run additionals commands when you hit a breakpoint; you can either add LLDB or Python commands and completely change the execution flow of the program with only breakpoints. See the command `breakpoint command` to further explanations.

Let's also mention watchpoints, which are a special type of breakpoint. Watchpoints act as monitors, they will be trigger when the value of a variable changes. This is very useful to identify the culprits of the side effects when the program has state issues.

# Going further

Before concluding, let's name some specific commands that you might find useful in some extreme cases. Better to know they exist, if someday you need them.

It is recommended to understand the calling convention of the CPU you are using (AArch32 or AArch64 architecture on iPhone), to fully understand what you are doing.

## Assembly

With the `disassemble` command you can disassemble specified instructions and get the assembly code.

## CPU

With the `register` command you can read and write directly into the registers of the CPU. 

## Memory

With the `memory` command you can read and write directly into the memory. Make sure you are allowed to access the memory space you are operating with.

# Conclusion

We only saw the small part of LLDB power and yet, when used correctly, these common LLDB commands will greatly increase your productivity, allowing to change and inject code. Mixing them with more advanced ones, and you will not feel the need to compile again.