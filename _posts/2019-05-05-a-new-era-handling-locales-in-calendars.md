---
title: 'A new era: handling locales in calendars'
categories:
- l10n
- swift
date: 2019-05-05 23:36 +0200
---
The vast majority of countries use the most widely known calendar, the Gregorian calendar. However, some locales use another calendar for various reasons. Japan is one of them.

The Japanese imperial calendar is quite unique. It is based on the legendary foundation of Japan. The calendar works like the Gregorian, except for years. Years are based on the reign of the current Emperor. When a new emperor access power, years go back to one. With each new emperor, a new era begins.

{% highlight swift %}
let dateFormatter = DateFormatter()
dateFormatter.calendar = Calendar.init(identifier: .japanese)
dateFormatter.locale = Locale(identifier: "ja_JP")
dateFormatter.dateStyle = .long
print(dateFormatter.string(from: Date()))
{% endhighlight %}

For example, this piece of code will show `平成31年5月5日`. Which is wrong. Why?

The Hensei era (平成) ended the 30/04/2019 and a new one began the 01/05/2019, the Reiwa era (令和). The corretc displayed date should be  `令和1年5月5日`.

The fact is, with these non-deterministic calendars, software manufacturers need to update their system with this new era to support it. For example, Apple issued the following in their latest beta software:

> Support for the Reiwa (令和) era of the Japanese calendar, which begins on
> May 1, 2019, is now available. The first year of Japanese-calendar era 
> is represented as  “元年” (“Gannen”) instead of “1年”, except in the 
> shorter numeric-style formats which typically also use the narrow era 
> name; for example: “R1/05/01”. (27323929)
>
> — iOS 12.3 Beta 4 Release Notes, macOS Mojave 10.14.5 Beta 4 Release Notes

At the moment I do not own a device with either of these betas, so I could not verify the update.

{% info %}
Fun fact: 2019 is both year 31 (Hensei) and year 1 (Reiwa), depending on the date.
{% endinfo %}

# Atypical calendar localization

The Gregorian calendar also uses eras, except it doesn't change often. It's the same for 2019 years, and counting : AD (Anno Domini). 

Since the imperial Japanese calendar heavily relies on eras, we need to take that factor in account when building our products.

Let's go back to our previous example. The code uses the predefined format styles for dates property provided by Apple, `dateStyle`. This property already considers the specifics of each calendar to display a properly formatted date.

> Based on the values of the `dateStyle` and `timeStyle` properties, `DateFormatter` provides a representation of a specified date that is appropriate for a given locale.
>
> — DateFormatter (Apple Documentation)

| Calendar / Locale |     ja_JP     |     en_US      |
| :---------------: | :-----------: | :------------: |
|     Japanese      | 令和1年5月5日 | May 5, 1 Reiwa |
|     Gregorian     | 2019年5月5日  |  May 5, 2019   |

However, what happens when we want to use our custom format without considering the locale ?

We do this using the `dateFormat` property. Replace the instruction containing `dateStyle` with the following:

{% highlight swift %}
dateFormatter.dateFormat = "dd/MM/yyyy"
{% endhighlight %}
{% warning %}
[Always use `yyyy`](https://gaelfoppolo.com/it-s-that-week-of-the-year/).
{% endwarning %}


| Calendar / Locale |   ja_JP    |   en_US    |
| :---------------: | :--------: | :--------: |
|     Japanese      | 05/05/0001 | 05/05/0001 |
|     Gregorian     | 05/05/2019 | 05/05/2019 |

We broke the era display. It only works for the Gregorian calendar. We don't know what first year of which era we are talking about. We could use the following date format `dd/MM/yyyy G` to display the era, but it would be ugly on Gregorian dates.

# Conclusion

The only time you're allowed to use a custom `dateFormat` is when you work with fixed format date representations, such as timestamps (RFC 3339). 

In any other case, especially if the date will be displayed to the user, you should use the `dateStyle` and `timeStyle` properties. 

Japan is not the only country with another calendar (China, Thailand, India, etc.), so let's keep the dates simple!