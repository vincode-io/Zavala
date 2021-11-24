---
layout: single
title: Text Formatting Philosophy
permalink: /help/Text_Formatting_Philosophy.md/
header:
  overlay_image: /assets/images/phone_and_laptop.png
  overlay_filter: 0.5
---



## Less is More

Text formatting in Zavala may feel a little restrictive at first. You can bold and italicize text and that is about it. But, there is a reason we don’t go all out and allow full Rich Text Formatting. Most of the reasons are because of how we use and publish writings in contemporary times.

## Colors

Color can be very useful for making text stand out. You can use it to make your font a different color or to support highlighting text. The main problem with color is that modern operating systems, and even websites, support light mode and dark mode versions of themselves.

It you’ve ever pulled up document that was written on a light mode system in one that is in dark mode, you are familiar with the problem. Black text on a dark background is illegible. The same problem happens with highlighting. Since we want to be able to edit and publish to modern platforms, we automatically switch the text color in the outline editor depending on the mode and don’t specify color formatting when publishing. 

## Fonts

People are very particular about fonts. Sometimes it is a matter of taste, sometimes it is a matter of accessibility. [Some fonts](https://brailleinstitute.org/freefont) are specifically designed to make reading more accessible to visually impaired readers.

Zavala supports customizing the fonts used in the user interface, but those aren’t embedded or specified in the outlines themselves. Using this approach allows users to pick the best fonts for their particular tastes or needs.

## Compatibility

We want to be able to publish and share outlines with as many applications and platforms as possible. To do that we use open and standard document formats. Two of the main document formats that we support are Markdown and OPML. The limits of these document formats inform which text formatting we allow.

## Text Formatting

Since OPML doesn’t support formatting, we use Markdown inside the OPML text fields. That allows us to have formatting that is only limited by Markdown’s syntax.

As of now, we only support the basic Markdown syntax. Extensions have been made to Markdown, and we don’t currently have any plans support them. 

Markdown supports bold, italics, links, and embedded images. It doesn’t support highlighting, strike-through, or [underlining](https://mobile.twitter.com/gruber/status/299372697593462784).

## Markdown, Wiki, and Twitter Syntax

Even though Markdown influences how we format text that we publish and share, we don’t use Markdown syntax when editing documents. We don’t use wiki links or Twitter hashtags either.

These syntaxes were designed to be used for plain text editing and often for web environments. They are effective, but can make documents look cluttered and confusing. Often times they have to be ran through a processor to generate HTML and viewed in a browser to look appealing.

Zavala is a native application and isn’t limited to plain text editing. So we can show **bold**, _italic_, [links](https://zavala.vincode.io), and even inline images without needing special syntax to do so. This allows us to work with attractive documents while still being compatible with the myriad systems that understand Markdown.

Beyond Markdown, we support tags that are different from your standard hashtag. You can have spaces in the name of Zavala tags and they are shown in a common location, just under the document title. 

In most systems you can put hashtags anywhere, and that is a double-edged sword. They look bad if you randomly sprinkle them about. But, they can provide additional context to their surrounding content (at the row level), which Zavala tags can’t. Look for us to address that in an upcoming update.

## The Future

A lot of care and thought has been put into text handling in Zavala. That doesn’t mean that is the end of the story. There are shortcomings in how we handle text in Zavala that we would like to address in future updates. The hard part will be doing so while sticking to our core philosophies.