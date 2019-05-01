---
title: OpenType SVG fonts are coming to Apple ecosystem!
date: 2018-07-09
categories: [ios, macos]
excerpt: While browsing the headers of the new Xcode 10 beta 2, I noticed a completely new framework in CoreText, confirming the upcoming support of color fonts in Apple ecosystem.
---

{% include 
    image.html 
    src="opentype-fonts-cover.png"
    alt="Gilbert, NTBixa and Abelone fonts"
    caption="Gilbert, NTBixa and Abelone fonts"
    style="big"
%}

Fonts, as we know them, only contain a single color information, using either vector or bitmaps. We call them monochromatic fonts. They do not contain any other color information. That's why a glyph (usually a character) can only have one color, by default black. 

The main font format nowadays is the Open Font Format (OFF), on which **OpenType** (OT) is based. Thanks to its flexibility, OpenType fonts are used commonly today on the major computer platforms.

**OpenType SVG** (OTS) is a new font format in which an OpenType font has all or just some of its glyphs represented as SVG artwork.  

This allows the display of multiple colors, gradients, shades and even transparency in a single glyph. 

We also refer to OTS fonts as “**color fonts**”, and you've been using them for years already.

## Emoji

The Unicode Standard began to add emoji in its sixth version, in late 2011. A lot of actors integrated them in their products and platforms, but this was just a start. Unicode emoji are handled as text, and color is an essential aspect of the emoji experience. This led to a need to create mechanisms for displaying multicolor glyphs. Each actor then created its own format to display it own emojis. So emojis are color fonts.

{% include 
    image.html 
    src="opentype-fonts-emoji.png"
    alt="Emoji are SVG fonts"
    caption="Emoji are SVG fonts"
%}

## Color font formats

All of major players have previously developed and implemented their own proprietary color formats to display emojis, for the gaming, or printing purpose.

There are two types of color fonts: the one using **vectors** or the ones using **bitmaps**. The major difference is that bitmaps' color fonts are not scalable and thus, they get bigger really quick.

There is a ton of color font formats, but today the three major are SBIX, CBDT and COLR.

| Name |   Actor   |  Type  |
| :--: | :-------: | :----: |
| SBIX |   Apple   | Bitmap |
| CBDT |  Google   | Bitmap |
| COLR | Microsoft | Vector |

As you see, no real consensus existed on that topic.

To address this fragmentation, Mozilla and Adobe decided to work on a new format, taking the best of all. Google and Microsoft also joined the battle, and in 2016, the OTS standard was born.

{% include 
    image.html 
    src="opentype-svg-logo.png"
    alt="OpenType logo"
    caption="OpenType logo"
    style="half"
%}

OTS is both SVG and bitmap compatible.

As you see, the OTS standard is relatively new, and therefore as of 2017, no operating system supports OTS fonts. But it's changing!

## OTS in Apple ecosystem

While browsing the headers of the new Xcode 10 beta 2, I noticed a completely new framework in CoreText, **OTSVG.framework**. 

Again some headers exploring, a quick search on the Internet and I stumble upon this tweet[^tweet], confirming my suspicion: OTS support is coming to Apple ecosystem!

You can also find the related new [data types](https://developer.apple.com/documentation/coretext/core_text_data_types?changes=latest_major&language=objc) and [functions](https://developer.apple.com/documentation/coretext/core_text_functions?changes=latest_major&language=objc) online.

{% include 
    image.html 
    src="opentype-core-text-datatypes.png"
    alt="CoreText datatypes"
    caption="GCoreText datatypes"
%}

{% include 
    image.html 
    src="opentype-core-text-functions.png"
    alt="CoreText functions"
    caption="CoreText functions"
%}

This new framework is available on iOS 12.0+, macOS 10.14+, watchOS 5.0+, tvOS 12.0+ starting Xcode 10 beta 2.

### How to use it?

Well, this is the easy part, you don't need to do anything else to use them. Either select the font in the Interface Builder or set it in the code. For example to use the [Playbox](https://colorfontweek.fontself.com/#playbox) font with a UILabel:

```swift
label.text = "An OpenType SVG font on iOS!"
label.font = UIFont(name: "PlayboxRegular", size: 30)
```

{% include 
    image.html 
    src="opentype-playbox-ios12.png"
    alt="Playbox font on iOS 12"
    caption="Playbox font on iOS 12"
%}

### What about retrocompatibility?

iOS 11 and previous **will not crash**, they'll just display a plain black version of the glyphs. That's neat, right?

{% include 
    image.html 
    src="opentype-playbox-ios11.png"
    alt="Playbox font on iOS 11"
    caption="Playbox font on iOS 11"
%}

### Font features

A ma­jor goal of Open­Type was to pro­vide bet­ter sup­port for in­ter­na­tional lan­guages than its pre­de­ces­sors. In order to do this, Open­Type introduced lay­out fea­tures, com­monly known as font features, that al­low fonts to spec­ify what and how these features should be in­serted into the text. And of course, color fonts have font features. 

But not all color fonts have all font features. So first we need to check what are the features available in the font. I choose the font [Trajan Color](https://typekit.com/fonts/trajan-color) as example. We use [CTFontCopyFeatures(_:)](https://developer.apple.com/documentation/coretext/1509767-ctfontcopyfeatures) to extract the font features.

```swift
let font = UIFont(name: "TrajanColor-Concept", size: 30)
let features = CTFontCopyFeatures(font)
```

Let's see the content of it. Don't forget to bring your [Font Feature Registry](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM09/AppendixF.html).

```json
(
    {
        CTFeatureTypeIdentifier = 0;
        CTFeatureTypeName = "All Typographic Features";
        CTFeatureTypeNameID = "-100";
        CTFeatureTypeSelectors =         (
            {
                CTFeatureSelectorDefault = 1;
                CTFeatureSelectorIdentifier = 0;
                CTFeatureSelectorName = On;
                CTFeatureSelectorNameID = "-101";
            }
        );
    },
     
    [...]

    {
        CTFeatureTypeIdentifier = 35;
        CTFeatureTypeName = "Alternative Stylistic Sets";
        CTFeatureTypeNameID = "-3600";
        CTFeatureTypeSelectors =         (
            {
                CTFeatureSelectorIdentifier = 2;
                CTFeatureSelectorName = Silver;
                CTFeatureSelectorNameID = 256;
            },
            {
                CTFeatureSelectorIdentifier = 4;
                CTFeatureSelectorName = Copper;
                CTFeatureSelectorNameID = 257;
            },
            
            [...]

            {
                CTFeatureSelectorIdentifier = 26;
                CTFeatureSelectorName = Salmon;
                CTFeatureSelectorNameID = 268;
            },
                
            [...]
            
            {
                CTFeatureSelectorIdentifier = 40;
                CTFeatureSelectorName = Solid;
                CTFeatureSelectorNameID = 275;
            }
        );
    }
)    
```

Let's take the one named  "Alternative Stylistic Sets". It's identifier is 35.

In your registry, find the one with the Feature Value equals to that value. [This one](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM09/AppendixF.html#Type35). The feature constant is `kStylisticAlternativesType`.

The `CTFeatureTypeSelectors` array below describe the values available for that feature.

Let's says I want the one named "Salmon", with the identifier 26. We need to find the selector value in the registry matching the identifier. Then retrieve the *Selector Constant* value, in the previous column, to activate it. In our case, the value is `kStylisticAltThirteenOnSelector`.

We now have the feature we want, need to add it to our font, using a `UIFontDescriptor`.

```swift
let alternativesType = [
	UIFontDescriptor.FeatureKey.featureIdentifier: kStylisticAlternativesType,
	UIFontDescriptor.FeatureKey.typeIdentifier: kStylisticAltThirteenOnSelector
]

let descriptor = font
            	.fontDescriptor
	            .addingAttributes(
    	            [UIFontDescriptor.AttributeName.featureSettings: [alternativesType]]
        	    )
```

Finally we create a new font with this new feature.

```swift
let salmonFont = UIFont(descriptor: descriptor, size: 0.0)
```

{% include 
    image.html 
    src="opentype-trajan.png"
    alt="Trajan font"
    caption="Trajan font"
%}

## Where can I get these gorgeous color fonts? 

Color fonts are still new and so hard to find. You can go to [colorfonts.wtf](https://www.colorfonts.wtf), which references most of them. And if you are inspired you can even create your own with a dedicated software, [Fontself](https://www.fontself.com/).

## What's next?

At the moment, the **OTSVG.framework** is only available in Objective-C, so I encourage you to browse the header of the framework if you want to go further. Watch closely the new betas and the documentation.

{% include 
    image.html 
    src="opentype-framework.png"
    alt="OTSVG.framework"
    caption="OTSVG.framework"
%}

There is still a lot to talk about and explore about color fonts and I hope these colorful fonts will appear on some iOS app in next fall!

## References

<https://helpx.adobe.com/typekit/using/ot-svg-color-fonts.html>

<https://www.colorfonts.wtf/>

<https://generic.cx/essays/font-descriptors/>

and a big thanks to Jean-Luc Jumpertz for the [idea](https://twitter.com/JLJumpertz/status/1009493272484630529)!

[^tweet]: [https://twitter.com/Litherum/status/1010205915641835521](https://twitter.com/Litherum/status/1010205915641835521)

