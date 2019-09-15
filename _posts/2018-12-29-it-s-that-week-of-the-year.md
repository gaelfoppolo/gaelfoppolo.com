---
layout: post
title: It's that Week of the Year
category: [ios, date]
---

As of most years, this year ends in the middle of a week. And according to the date format you are using, it will not display the same date value during these last few days.

It's the perfect time to remind everybody that date formatting can be tricky, if you are not looking closely enough.

{% highlight swift %}
let formattery = DateFormatter()
formattery.dateFormat = "d-MM-y"
let datey = formattery.date(from: "29-12-2018")

let formatterY = DateFormatter()
formatterY.dateFormat = "d-MM-Y"
let dateY = formatterY.date(from: "29-12-2018")
{% endhighlight %}

This will yield the following results:

```
"29 Dec 2018 at 00:00" (datey)
"25 Dec 2017 at 00:00" (dateY)
```

Notice the date format: the first use `y` , known as year calendar and the latter `Y`, known as year-week calendar.

# ISO year-week calendar

As defined in ISO 8601, a year-week calendar has 52 or 53 full weeks. Meaning a year has either 364 or 371 days instead of the usual 365 or 366 days.

The first ISO week of the year is calculated according to a bunch of properties, and in the end, can begin from 29 December to 4 January. The minimum days in a week is 4 and first day of the 
week is Monday, according to ISO 8601 specifications. You can retrieve these values from [minimumDaysInFirstWeek](https://developer.apple.com/documentation/foundation/calendar/2293094-minimumdaysinfirstweek) and [firstWeekDay](https://developer.apple.com/documentation/foundation/calendar/2293656-firstweekday).

{% highlight swift %}
let calendar = Calendar(identifier: .iso8601)
// calendar.minimumDaysInFirstWeek
// calendar.firstWeekday
{% endhighlight %}

For example, 1 January 2019 is a Tuesday. Then the first year-week of 2019 starts on 31 December 2018 and ends on 6 January 2019. 

{% include 
	image.html 
	src="yyyy-january-2019-monday.png"
    alt="January 2019 starts on Tuesday"
    caption="January 2019 starts on Tuesday"
%}

However, if the first day of the week was Thursday, then the first year-week of 2019 would have started on 3 January, and would have ended on 9 January. The first two days of 2019 would have then been part of year-week 53 of 2018.

{% include 
	image.html 
	src="yyyy-january-2019-thursday.png"
    alt="January 2019 starts on Thursday"
    caption="January 2019 starts on Thursday"
%}

ISO year 2019 starts in year 2018, meaning the first ISO week of 2019 is also considered as the week 53 of ISO year 2018.

# ISO year-week date format

Using the `Y` date format, you specify the year-week date format, which needs additional components from the same year-week date format. `d` and `M` are respectively day of the month and month, but in year based date format. This is why the formatter ignores both of them and only consider the `Y`. 

Without any other configuration, the formatter only consider the year, in a year-week calendar, and by default uses a zero based index for the day and the week: day 0 of week 0 of 2018 is 25 December 2017.

{% include 
	image.html 
	src="yyyy-december-2018.png"
    alt="December 2018"
    caption="December 2018"
%}

When using year-week date format, use `w` to specify the week of year (ordinal) and `e` to specify the day of week. 

{% highlight swift %}
let formatterY = DateFormatter()
formatterY.dateFormat = "e-w-Y"
let dateY = formatterY.date(from: "29-12-2018")
{% endhighlight %}

And you'll get **`"19 Mar 2018 at 00:00"`**. Why?

We changed the date format but forget the date representation! The formatter is now using year-week date format ; what it reads is: day 1 ($29 \bmod 7 = 1$) of week 12 of year 2018. And this is 19 March 2018.

We need to update the date representation to respect that format.

{% highlight swift %}
let dateY = formatterY.date(from: "6-52-2018")
{% endhighlight %}

Day 6 of week 52 of year 2018. Finally!

# y vs Y

**Typically you should use the calendar year format, `y`**. `Y` should be used only when you specifically need to work with an **ISO week date** system. This can be the case for fiscal years.

Also, you should only use `y` and not `yyyy`. Unicode Technical Standard #35 explains this causes a forced padding, which you want to avoid if you work with non-Gregorian calendar. Using `y` will also enable forward compatibility.

{% include 
	image.html 
	srcabs="https://imgs.xkcd.com/comics/iso_8601_2x.png"
	url="https://xkcd.com/1179/"
    alt="XKCD #1179"
    caption="XKCD #1179"
	style="half"
%}

# Reference

[https://www.iso.org/iso-8601-date-and-time-format.html](https://www.iso.org/iso-8601-date-and-time-format.html)

[http://unicode.org/reports/tr35/tr35-10.html#Date_Format_Patterns](http://unicode.org/reports/tr35/tr35-10.html#Date_Format_Patterns)

[https://developer.apple.com/documentation/foundation/dateformatter](https://developer.apple.com/documentation/foundation/dateformatter)