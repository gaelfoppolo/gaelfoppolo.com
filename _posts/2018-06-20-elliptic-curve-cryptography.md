---
title: Elliptic-curve cryptography (ECC)
date: 2018-06-20
categories: cryptography math security

---

Elliptic-curve cryptography (ECC) is a public-key cryptography system, very powerful but yet widely unknown, although being massively used for the past decade.

Elliptic curves have been studied extensively for the past century and from these studies has emerged a rich and deep theory. On one hand, it’s easy to describe elliptic curves, but on the other, the mathematical concepts and theorems on which they rely are tough to understand. While others public-key cryptography can be easy explained and understood, ECC is still a complicated topic to discuss in simple terms.

Since elliptic curves provide us with some of the strongest and most widely used encryption protocols, understanding elliptic curves would give insight into the security of these protocols. NIST standard provides recommended parameters for curves that can be used for elliptic curve cryptography. These recommended parameters are widely used; and it is widely presumed that they are a reasonable choice. But some suspicions led to the idea that these parameters could have been specially "cooked" by the NSA, to offer them a backdoor in ECC.

Whether or not this assumption reveals itself true, history has made it clear that blindly accepting the word of the experts is not an acceptable course of action. What we really need is more understanding of cryptography.

This post is here to cover the basics of ECC: what it is, how it works and some current applications. However, it will require some mathematical background in number therory, field theory and finite geometry. Don’t run away because I will explain a lot of concepts so no need to worry. Still here? Okay great. 

Hot beverage, pen and paper ready? Let's begin with the classical, everlasting, but always useful, definition:

>  Elliptic-curve cryptography (ECC) is an approach to public-key cryptography based on elliptic curves over finite fields.

Let's break down each concept and explain them.

## Public-key cryptography

Public-key cryptography purpose is to securely transmit a message over an insecure channel. That's means that only the person who receives the message can decipher it, and read it. Even if a malicious third-party intercept the message or discover the method of encryption, the message cannot be read.

In public key cryptography, there are two keys: one to encrypt (public) and the other to decrypt (private).

Public-key cryptography is based on the existence of trapdoor function. A **trapdoor function** is a function that is easy to compute on every input, but hard to invert given the output, without "a special information".

- Given $x$, it's easy to compute $f(x)$
- Given $f(x)$, it's hard to compute $x$
- But, given $f(x)$ and the trapdoor, it's again easy to compute $x$

A **trapdoor function** relies on mathematical problems that admit no efficient solution (yet), so that computing $f(x)$ is easy while finding $x$ from $f(x)$, without knowing the trapdoor is considerated hard.

### RSA

RSA's trapdoor function is written as exponentiation modulo a composite number and is related to the problem of prime factorization. Put in simple words: it is very simple to multiply numbers together, but it can be very difficult to factor numbers.

A quick example to illustrate: suppose I give you the number 3369993333393829974333376885877453834204643052817571560137951281149 [^bigPrime].  Can you tell me what are the two integers I multiply to get it, in a relative short amount of time? RSA works like that. Basically, the two prime numbers are the private key and the computed number is the public key.

If we transpose to our trapdoor function:

- define $p$, $q$ two random prime numbers 
- calculate $n = pq$ and $\phi(n) = (p-1)(q-1)$[^totientFunction]
- pick a number $d$ such as $d << n$
- calculate $e = d^{-1} \bmod \phi(n)$. Note that $ed \equiv 1 \bmod \phi(n)$ and $gcd(e, \phi(n)) = 1$[^gcdFunction]

$(n, e)$ is the public key, $d$ the private key, $m$ the message to send.

Using the public key, you can encrypt the message:

$$ E = m^e \pmod n $$

and send $E$ over the insecure channel.

Using the private key, you can decrypt $E$

$$ D = E^d\pmod n $$

Which is possible due to Euler's theorem:

$$ D = m^{ed} \pmod n\\
= m^{1 \bmod \phi(n)} \pmod n\\
= m  \pmod n
$$

To « crack » the code, the attacker needs to figure out $d$ (the private key), from $E$, knowing only $n$ and $e$. Meaning factoring $n$ into $p$ and $q$, to get $\phi(n)$ and then $d$.

But what is the problem with this system?

To store the big integer $n$ in the public key, we need as much as bits as the integer size. For example, to store an integer between $2^{255}$ and $2^{256}-1$, we need at least 256 bits. But factoring algorithms get more and more efficient each days, and with the number of resources available (ie. cloud) also growing, the size of the public keys keep growing. For example, NIST recommends 2048-bit keys for RSA nowadays.

However, this is not a sustainable situation for mobile and low-powered devices that have limited computational power. All this means is that RSA is not the ideal system for the future of cryptography. We need a better system. That's where elliptic curves come into play.

## Elliptic curves

Elliptic curves have nothing to do with ellipses, so put ellipses and conic sections out of your mind. Elliptic curves are used in various areas of mathematics and theoretical physics. But cryptography is the field where they are the most used. Let's see what make them so special.

First of all: what is an elliptic curve?

An elliptic curve is a the set of solutions to a cubic function of two variables $x$ and $y$. More precisely, it is a non-singular (does not cross over itself, no single points) cubic curve that verifies the equation:

$$ y^2 = x^3 + ax + b $$

The curve also have an additional point at infinity, $O$. In geometry, a point at infinity or ideal point is an idealized limiting point at the "end" of each line. Geometrically, it can be thought of as a point infinitely high (and low) on the $y$-axis. This will be useful in the definition of the group law given in the next part. 

We define $E(\mathbb{R})$, an elliptic curve over real numbers, as following:

$$ E(\mathbb{R}) = \{ (x, y) \in \mathbb{R}^2 : y^2 = x^3 + ax + b \} \cup \{O\} $$

with $O$ of coordinates $(0,1,0)$.

No really useful yeah? Let's see so graphical representation of an elliptic curve in $\mathbb{R}$, with $a = -1$ and $b = 1$ which is denoted by $E(\mathbb{R})$.

{% asset ecc-elliptic-curve-real.png alt='Elliptic-curve in $\mathbb{R}$'%}

The curve can also have two separate components. We can also have a representation in $\mathbb{C}$, denoted by $E(\mathbb{C})$, where the points form a torus (the mathematical term for the surface of a donut).

{% asset ecc-torus.png alt='Elliptic-curve in $\mathbb{C}$'%}

A quick note: the equation above is a special form, the **reduced/short Weierstrass normal form**. There are also a couple of interesting forms:

- the **Weierstrass form**: $y = x^3 + dx^2 + ex + f$
- the **extended Jacobi quartic form**: $y^2 = dx^4 + 2ax^2 + 1$
- the **twisted Hessian form**: $ax^3 + y^3 + 1 = dxy$
- the **twisted Edwards form**:  $ax^2 + y^2 = 1 + dx^2y^2$ (used in [EdDSA](https://en.wikipedia.org/wiki/EdDSA))
- the **twisted Jacobi intersection form**: $bs^2 +  c^2 = 1, as^2 + d^2 = 1$

Raw elliptic curves are really weird, both visually and to work with, so the type of elliptic curves we will use is the **reduced/short Weierstrass normal form**.

We have now a little more insight of what is an elliptic curve, but just with that, we cannot understand **yet** why they are so interesting and useful.

## Algebraic structures

Often, cryptosystems require the use of algebraic structure, because they offer a ton of useful properties. That was the case for RSA, even if we skip that aspect earlier. So before we continue, a quick part on the mathematical definition of various useful algebraic structures used in cryptography. This is going to be a little theoretical, so hang on and bear with me.

### Group

A **group** $G$ is a set (non-empty) of elements with a binary operation $+$ (the group law).

$$ G + G \rightarrow  G\\
(x,y) \rightarrow x + y $$

A group also satisfies the following properties:

- Closure: $\forall~x, y \in G, x + y \in G$
- Associativity: $\forall~x, y \in G, (x + y) \cdot z =x + (y + z)$
- Neutral element: $\exists~e \in G, \forall~x \in G, x + e = x$
- Inverse element:  $\forall~x \in G, \exists~y \in G, x + y = e$

**Warning**: Do not confuse this group law with the traditional addition. We will see when working with elliptic curve, an example of that.

Basically, a group $G$ takes two elements $x$ and $y$ of $G$ and combines them with the operation $+$ to produce a third element of $G$. When a group is also commutative, the group is know as an **abelian group**.

The most common group you know is $\mathbb{R}$, all the numbers, where the operation is $+$ (the addition we all know), the neutral element is 0 and the inverse of an element $x$ is $-x$.

#### Order of the group

The number of elements in a group $G$ is denoted $\vert G \vert$ or $ord(G)$. If the order of a group is a finite number, the group is said to be a **finite group**. Basically speaking, a finite group is a group with a finite number of elements.

The order of an element $x$ of a finite group $G$ is denoted $\vert x \vert$ or $ord(x)$. It is the smallest positive integer $n$ such that $x^n = e$, where $e$ is the identity element.

#### Cyclic group

A cyclic group $G$ is a group that can be generated by a single element $g$, called the generator and denoted $ \langle g \rangle$.

$$ G = \langle g \rangle = g^m $$

where $m$ is a positive integer. Every element $a$ in $G$ has the form $g^i$ where $0 \leq i \leq m$.

An example: the set of integers, with the operation of addition, forms a group. It is a cyclic group, because all integers can be written as a finite sum or difference of copies of the number 1. 1 is then a generator of this group.

Two interesting properties: 

- a group $G$ where the order is a prime number is a cyclic group. It can be demonstrated using Lagrange's theorem[^lagrange].
- a cyclic group $G$ contains exactly $\phi(n)$ generators, where $n = \vert G \vert$

#### Subgroup, cyclic & order

A subgroup is a group which is a subset of another group. 

{% asset ecc-subgroup.png alt='H is a subgroup of G' %}

$H$ is a subgroup of $G$. Yeah, that was easy.

All subgroups of a cyclic group are also cyclic. That's cool, because cyclic subgroups are the foundations of ECC and other cryptosystems.

#### Cofactor

A cofactor is the ratio between the order of a group $N$ and the order of the subgroup $n$: 

$$ h = N/n $$

For any finite group $G$, the order of every subgroup $H$ of $G$ divides the order of $G$[^lagrange]. So $h$ is always a positive integer.

### Ring

A **ring** $R$ is a subtype of group. It's a set (non-empty) with two binary operation $+$ ("addition") and $\cdot$ ("multiplication"). It also satisfies the following properties:

$$ R + R \rightarrow  R, (x,y) \rightarrow x + y\\
R \cdot R \rightarrow  R, (x,y) \rightarrow x \cdot y $$

- $(R, +)$ is an abelian group, with the $+$ identity denoted by 0
- For the "multiplication":
  - Associativity: $\forall~x, y \in R, (x \cdot y) \cdot z =x \cdot (y \cdot z)$
  - Distributative: the "multiplication" distributes over "addition",  $\forall~x, y, z \in R, (x + y) \cdot z = x \cdot z + y \cdot z, x \cdot (y + z) = x \cdot y + x \cdot z, $

A couple of properties to have in mind:

- If the multiplication is commutative, $R$ is *commutative ring*.
- If there is a neutral element for the multiplication, $R$ is a *ring with identity*: $\exists~e \in R, \forall~x \in R, x \cdot e = x$

As example, $\mathbb{R}$ is also a ring (a commutative ring with identity even) where the second operation is $\times$ (the multiplication we all know), the neutral element of this second operation is 1. 

### Field

A field $F$ is special type of ring, in which every nonzero element has a multiplicative inverse. It's a set (non-empty) with two binary operation $+$ ("addition") and $\cdot$ ("multiplication").

- $(F, +)$ is an abelian group, with the $+$ identity denoted by 0
- $(F \setminus \{0\}, \cdot)$ is a abelian group, with the $\cdot$ identity denoted by 1
- The distributative law holds
- Inverse element for the "multiplication": $\forall~x \in F, \exists~y \in F, x \cdot y = e$

The rational numbers $\mathbb{Q}$, the real numbers $\mathbb{R}$, and the complex numbers $\mathbb{C}$ are all fields. For $\mathbb{R}$, the inverse of an element $x$ is $\frac{1}{x}$.

-------

Okay, let's take a minute to digest that. Read again if needed, it's a lot to take in.

------

As you see, the design of mathematics encompasses a number of other principles that are also present in software engineering. Abstract algebra is essentially an exercise in object hierarchy design, where the goal is to use as few ingredients as possible, adding one more ingredient at a time, to see what kinds of interesting and useful constructs we can get.

{% asset ecc-hierar-algebraic-structure.png %}

With that inheritance, a field can be finite, infinite, cyclic or not. But what is interesting us here are finite fields.

### Finite fields

A finite field is like a finite group: it has a finite number of elements. It's traditionally denoted $\mathbb{F}_q$ for some integer $q$, which is the size (order) of the field.

However, finite fields are so special that there are only two kinds of finite fields. 

One kind is the field formed by addition and multiplication modulo a prime number. The other kind of finite field has a number of elements that is a power of a prime number. The addition operator consists of multiple independent additions modulo that prime. The elements of the field can be thought of as polynomials whose coefficients are numbers modulo that prime.

All finite fields, but particularly those of this second kind, are known as *Galois fields*.

Constructing finite fields is beyond the scope of this post, but there are plenty of great resources on the Internet if you want to know more about it.

There exists a finite field $\mathbb{F}_q$ if and only if $q=p^m$ for a prime $p$ and an integer $m \leqslant 1$. The elements of the prime field of order $q = p^1$ may be represented by integers in the range $[0;p−1]$.

For example:

- $\mathbb{F}_{16}$ is a finite field: the order is $2^4$.
- $\mathbb{F}_{17}$ is also one: 17 is prime, but it can also be viewed as $17^1$.

### Modular Arithmetic

Recall that a **prime number** is an integer that has as its only factors 1 and itself.

Modular arithmetic is basically doing operations (like addition and multiplication) not on a line, as you usually do, but on a circle ; the values "wrap around", always staying less than a fixed number called the modulus. Modular arithmetic is quite familiar, as we use it in our daily lives, when calculating hours for example.

## Group applied on elliptic curve

Back to our elliptic curves. We have defined some algebraic structures. Let's see how they relate to our curves.

The deep idea is that the points on an elliptic curve have an *algebraic structure*. What I mean by this is that you can “add” points in a certain way, and it will satisfy all of the properties we expect from our structure.

An elliptic curve group over real numbers ($\mathbb{R}$) consists of the points on the corresponding elliptic curve ($\mathbb{K}$). The addition of two points in an elliptic curve is defined, so it provides us a way to generate points on the curve from other points. And that is what makes the theory of elliptic curves so special and interesting.

The group law is defined as follow: given $P$, $Q$ and $R$, 3 $\mathbb{K}$-points distinct, and aligned on the curve, $P + Q + R = 0$, the point of infinity.

But how to perform this addition? And the multiplication?

### Geometrically

We can define the group law geometrically.

Given $P$ and $Q$ on the curve, we can write $P + Q = -R$. In details, the nominal case is:

- Take 2 $\mathbb{K}$-points, $P$ and $Q$, distinct, with $P \neq Q$.
- Draw a line through them and compute the third point $-R$, the intersection of the curve and the line.
- Take $R$ by by reflecting $-R$ it across the $x$-axis.

{% asset ecc-geometrically.png %}

There are a few odd cases, such as $P = Q$, $P = -Q$, $P = 0$, etc. that are easily resolved thanks to the point of infinity $O$, the neutral element of the group. Neat.

**Warning**: Do not confuse this group law with coordinate-wise addition. If $(1,2)$ and $(3,4)$ are points on an elliptic curve, their sum will not be $(4, 6)$. The group law obeys many of the same rules that regular addition does, but the point $P+Q$ is best described geometrically and has no simple algebraic formula to describe it.

### Point adding 

Although the previous geometric approach of elliptic curves provides an excellent method of illustrating elliptic curve arithmetic, it is not a practical way to implement arithmetic computations. However, algebraic approach is constructed to efficiently compute the geometric arithmetic.

Again, let's take, 2 $\mathbb{K}$-rational points, non-zero, distinct, $P$ and $Q$. Define the coordinates:

$$ P = (x_P, y_P)\\
Q = (x_Q, y_Q) $$

We can easily define the slope $s$ of the line passing though $P$ and $Q$:

$$ s = \frac{(y_P - y_Q)}{(x_P - x_Q)} $$

Since we know $P + Q = -R$, we can also express the coordinates of $R$:

$$ x_R = s^2 - x_P - x_Q \\
y_R =  s(x_P - x_R) - y_P $$

There is a special case when $P = Q$, because the line is now a tangent line. 

This case is only interesting when $y_P \neq 0$, else the tangent line does not intersect the curve at any other point and $P = Q = O$, the point of infinity. Adding $P$ to itself will create a new point yes, but this point would always be the same, $O$.

When $y_P \neq 0$, we can rewrite our law group to be: $P + P = R$. The equation of the slope become:
$$
s = \frac{3{x_P}^2 +a}{2y_P}
$$
And the coordinates of $R$:
$$
x_R = s^2 - 2x_P\\
y_R =  s(x_P - x_R) - y_P
$$
What if we continue to add P to itself, over and over?

### Point multiplication

Point multiplication or scalar multiplication, is the multiplication of a vector by a scalar, which give a new vector. On elliptic curve, point multiplication is the operation of adding a point $P$ on the curve to itself $n$ times.
$$
nP = Q\\
\underbrace{P+\dots+P}_{\text{n times}} = Q
$$
In $\mathbb{R}$, the coordinates of the new point $Q$, each time we increase $n$, get very large very quickly. That's because there is no "limit", there is an infinite number of points. It's work, but the number get very big, and round-off errors might appear.

As you see, expressing the geometric arithmetic is quite simple and straightforward. But what is that **trapdoor function** I talk about earlier? Well it's right above!

- Given $n$ and $P$, it's easy to compute $Q$
- Given $P$ and $Q$, it's hard to compute $n$

This problem is known as the **logarithm problem**, and there no known "easy" algorithm to solve it. However, the round-off errors might give us insights and clues about the curve and with a little more work, we could come up with a "efficient" algorithm that solve our particular problem. We need to refine and add more ingredients to make it work.

## Elliptic curve over finite field

So far we only worked with a "simple" group. We did not use any of our properties, like cardinality, subgroup or cyclic. Let's see how it can help us here and improve our understanding.

An essential property for cryptography is that a group has a finite number of points. Indeed, calculations over the real numbers are slow and inaccurate due to round-off approximations. Cryptographic applications require fast and precise  arithmetic. As finite fields are well-suited to computer calculations, they are used in elliptic curve ; thus elliptic curve groups over the finite fields of $\mathbb{F}_q$ are used in practice. We can now restrict elliptic over finite fields. Our equation from the begging now change to:
$$
E(\mathbb{F}_q) = \{ (x, y) \in (\mathbb{F}_q)^2 : y^2 \equiv x^3 + ax + b \pmod q \} \cup \{O\}
$$
In his 1901's paper *Sur les Propriétés Arithmétiques des Courbes Algébriques*, Poincaré stated the following theorem:

> Let $\mathbb{F}$ be a field and $E$ an elliptic curve. Let $E(\mathbb{F})$ the set of points of $E$ with coordinates in $\mathbb{F}$. Then $E(\mathbb{F})$ is a subgroup of the group of all points of $E$.

But remember a finite field $\mathbb{F}_q$ have a limited number of elements. So the curve cannot contain more than $q^2+1$ points (including the point at infinity), which means that the elliptic curve is also a finite set of points. [Hasse's theorem](https://en.wikipedia.org/wiki/Hasse%27s_theorem_on_elliptic_curves) provides an estimate of the number of points on an elliptic curve over a finite field, if you're interested.

Let's see a graphical representation. This is the elliptic curve with $a = -1$ and $b = 0$ as parameters, in the finite field $\mathbb{F}_{61}$ (61 is a prime number).


{% asset ecc-over-z.png %}

Beautiful right? There is no curve now, but we can still see an imaginary horizontal line that mirror the graph.

### Point adding

Since the curve consists of a few discrete points, it's not clear to understand how to "connect the dots" to make their graph look like a curve. It's not clear how geometric relationships can be applied. As a result, the geometry used in elliptic curve groups over real numbers cannot be used for elliptic curve groups over $\mathbb{F}_q$. Well, no, we can apply geometric relationships but it is odd. You can still draw a line through two dots and hit another. In case your not, you need to "wrap", like in the game Snake. If you hit left edge, you continue from the right edge, and vic versa. Same with top and bottom edges.

However, the algebraic rules for the arithmetic can be adapted for elliptic curves over $\mathbb{F}_q$. Unlike elliptic curves over real numbers, computations over the field of $\mathbb{F}_q$ involve no round-off error. The coordinates from the previous section now change to:
$$
x_R = s^2 - x_P - x_Q \pmod q\\
y_R =  s(x_P - x_R) - y_P \pmod q
$$
As you see, they are the same, we only added the modulus! Neat.

Let's not tackle the real interesting part of all of this: points multiplication over finite fields.

### Point multiplication

Multiplication over points for elliptic curves in $\mathbb{F}_q$ become really interesting when we put all the pieces together.

On $\mathbb{F}_q$, we have an order. And remember that a group where the order is a prime number is a cyclic group. So $\mathbb{F}_q$ is a cyclic group with $\phi(q)$ generators. According to Poincaré, $\mathbb{F}_q$ is even a subgroup. We now have a cyclic subgroup.

What we need now is a generator, to generate all the points in our subgroup. For practical usage of elliptic curves, we use a conventional generator $G$ which is a point on the curve. Finding a generator is not that hard, it's a relative simple process, but it can be time consuming. That why standard curves exist, see [Standards](#standards).

We can now modify a little our equation to use our generator as the "base point" $P$, to generate all the points:
$$
G^n = Q\\
\underbrace{G\cdot \ldots \cdot G}_{\text{n times}} = Q
$$

And now I ask again: what about the other way around? Having $Q$, the last-produced point, $G$ and the origin point, can we find easily find $n$?

Let me give you an intuitive example: let's say it's 8:54am on the clock, and call it $P$. Add 6h32min $n$ times. $n = 10^6$ or $n = 10^6 + 1$. This will produce a time $T$. I give you $P$ and $T$, what is $n$? Exactly. Reverting this process can only be done by trying out all possible $n$ and is impossible if $n$ is "large". 

> Finding the order of the element of a group is at least as hard as factoring.
>
> — Meijer, 1996[^factoGroup]

This is the root of ECC security. This problem has even a name. It's known as the **discrete logarithm problem** and more precisely when applied on elliptic curve, as the **elliptic curve discrete logarithm problem** (ECDLP). 

The security of elliptic curve cryptography depends on the ability to compute a point multiplication and the inability to compute the multiplicand given the original and product points.

Breaking the discrete logarithm problem is beyond the scope of this post, but you can look into baby-step, giant step, Pollard's rho, etc. if you're interested.

## Domain parameters

To use ECC, all parties must agree on all the elements defining the elliptic curve, that is, the *domain parameters* of the scheme. When using the **reduced/short Weierstrass normal form** here are the parameters:

- the elliptic curve is defined by $a$ and $b$
- the finite field is defined by $p$ and $m$ ($q = p^m$)
- the generator $G$, which is a point of the curve
- the order $n$ of the subgroup generated by $G$
- the cofactor $h$

In a concise form, the domain parameters are $(a,b,p,m,G,n,h)$.

And the values of the keys are:

- the **private** is an integer $d$, where $1 \leqslant d \leqslant n-1$
- the **public** is a point $E = dG$

## How good is ECC?

You might think that with all these parameters, the size of the public would be bigger than RSA? But you’re wrong. Looks closely. Each parameter is quite small, easy to store, the only ones that stand are $p$ and $m$, but they remain relatively small. Why it’s important? In a world where privacy and smartphones become the rules, more cryptography is done of these devices. Theses devices do not have infinite power and we come to the fact that multiplying two **very large** prime numbers is no longer easy, fast and efficient on them. While we could continue to increase the size of RSA key to keep it a secure solution, it’s not a viable one.

>  With every doubling of the RSA key length, **decryption is 6-7 times slower**. 

{% asset ecc-rsa-decryption-time.png %}

ECC in the other hand require much less storage, hence smaller keys, to ensure the same level of security. Here a comparative table between keys size in bits.

| ECC  |  RSA   | Ratio |
| :--: | :----: | :---: |
| 160  | 1 024  |  1:6  |
| 256  | 3 024  | 1:12  |
| 384  | 7 680  | 1:20  |
| 512  | 16 360 | 1:30  |

Not convinced yet? How about some "cryptographic carbon footprint"? Lenstra introduced this measure which can be described as following: how much energy is needed to break a cryptographic algorithm and compare that with how much water that energy could boil (keys size in bits).

|  RSA   |   Security level    | ECC  |
| :----: | :-----------------: | :--: |
|  242   |      Teaspoon       | ~95  |
|  754   |        Pool         | ~145 |
| 1 440  |   Lake of Geneva    | ~180 |
| 2 380  |        Earth        | ~235 |
| 2 730  |    Solar system     | ~250 |
| 14 954 | Observable universe | ~500 |

How about now?

## Standards

The generation of domain parameters is not usually done by each partie because this involves computing the number of points on a curve, find all the divisors, and then find a generator, which is both time-consuming and troublesome to implement. As a result, several standard bodies published domain parameters of elliptic curves for several common field sizes. Such domain parameters are commonly known as "standard curves" or "named curves". Multiples standards documents define them, but the most famous is the **NIST FIPS 186-3**, published in 2000.

For example the **ANSSI FRP256v1** elliptic curve is defined with the following domain parameters:

| Parameter |                            Value                             |
| :-------: | :----------------------------------------------------------: |
|     a     | 109454571331697278617670725030735128145969349647868738157201323556196022393856 |
|     b     | 107744541122042688792155207242782455150382764043089114141096634497567301547839 |
|     q     | 109454571331697278617670725030735128145969349647868738157201323556196022393859 |
|    G.x    | 82638672503301278923015998535776227331280144783487139112686874194432446389503 |
|    G.y    | 43992510890276411535679659957604584722077886330284298232193264058442323471611 |
|     n     | 109454571331697278617670725030735128146004546811402412653072203207726079563233 |
|     h     |                              1                               |

*Note: ANSSI is the French Network and Information Security Agency.*

Cryptography is about trust. The problems begin when this trust is broken. And this is what happened in 2013. NSA internal memos leaked thanks to Edward Snowden, suggesting that an algorithm developed by them and used in the generation of elliptic curves by NIST was containing a weakness, a backdoor, only known by the NSA. Since then, many experts expressed their concern over the security of the NIST recommended elliptic curves and suggested to use other standards, such as academics.

## Applications

Back to the main topic of this post: elliptic-curve cryptography. We now understand what's is, how it works, and why it's great. But what are the applications?

Well, elliptic curves are applicable for encryption, digital signatures, pseudo-random generators and many other purposes. The two most known algorithms based on ECC are:

- **ECDH** (Elliptic Curve Diffie-Hellman), used for encryption
- **ECDSA** (Elliptic Curve Digital Signature Algorithm), used for digital signing

These algorithms are used in many applications such as iMessage, Apple Pay, SSH, TLS or Bitcoin.

For example, when you browse a website and check their SSL certificate, you could see something like this:

{% asset ecc-ssl.png %}

This is ECDH at work. How to retrieve the parameters for that standard curve? From a terminal, with `openssl` installed:

```shell
openssl ecparam -name secp256r1 -param_enc explicit -text -noout
```

{% asset ecc-ssl-terminal.png %}

And as a bonus, the list of available curves like so:

```shell
openssl ecparam -list_curves
```

## Where to go now?

Beyond the trust issue evoked earlier, the core problem of ECC is implementation. If you implement the standard curves, chances are you're doing it wrong. A good, valid implementation of the standard curves is possible but very hard. If you implement ECC in your system, take a moment to consider the curves available and choose the ones that allow a simple and so, a secure implementation. Most of the ECC attacks succeed not because they solved the ECDLP but rather because they use weakness(es) of your implementation.

Yet, there are so much more to explore now that you know the basics! 

- We can try to implement some of these algorithms (ECDH for example)
- We can explore the others types of curves and fields (some of them mentioned in the [Elliptic curves](#elliptic-curves) section), if you're into maths

Or maybe go even further and explore quantum cryptography? 

Indeed, both RSA and ECC are not quantum-proof. With the rise of quantum computing, maybe in next decade these cryptosystems will not be viable anymore, but for the moment they remain the only good alternative to others cryptosystems.

[^bigPrime]: $2^{221} - 3$, which is prime
[^totientFunction]: Euler's totient function
[^gcdFunction]: Greatest Common Divisor
[^factoGroup]: Groups, Factoring, and Cryptography, *Math. Mag. 69*, 103-109
[^lagrange]: Lagrange's group theorem