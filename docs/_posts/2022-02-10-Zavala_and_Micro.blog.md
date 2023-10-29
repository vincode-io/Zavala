---
title: Zavala and Micro.blog
---



## Dog-fooding Zavala

One of the main problems with running a small open source project is getting it tested sufficiently. I use TestFlight to distribute test versions of Zavala so that users can test it out. My problem is that the pool of users willing to donate time to testing is too small. One of the ways to offset this is to do what we call dog-fooding in the IT world. It means “eat your own dog food” with the idea being if you were a dog food manufacturer, you should eat your own product for quality control.

I needed to spend as much time as possible in Zavala to effectively dog-food it. It could already be used as a [rudimentary word processor by using the Notes field](https://zavala.vincode.io/help/The_Notes_Field.md/#alternate-usage). In fact, it is kind of a nice writing experience if you are the type that typically starts a paper or article by outlining it. When writing I typically like to open a dedicated outline window by double clicking it (on the Mac) in the Documents view (the middle panel).

![](/assets/images/521C0463-6B21-4315-BF57-DFA477E97FA4.png)￼

There are several ways to print and export outlines in Zavala. The “Doc” export and print work best for this style of usage. But, what if I could publish to more than just Markdown and PDF files? What if I could use Zavala to publish to blogs?

## Blogging with Zavala

Once I decided that I wanted to blog with Zavala, I had to come up with an approach. I wanted to be able to publish to Micro.blog where I host my personal blog. I also wanted to be able to blog using GitHub pages where this blog is hosted. One thing I didn’t want to do is to build blogging directly into Zavala. That would make Zavala’s purpose confusing. I didn’t want users to feel like it was a blogging platform.

## Shortcuts to the Rescue

About the same time as I was thinking about blogging with Zavala, Apple announced [Shortcuts for macOS](https://support.apple.com/guide/shortcuts-mac/welcome/mac). This was fortunate. I had always intended to have some kind of cross-platform automation support for Zavala. Now that Apple had made strategy in this space clear, I had direction. Now I just had to implement it. I decided to start with my personal blog on Micro.blog.

## Humboldt

I contacted [Manton Reece](https://www.manton.org) to discuss my integration options. He is the creator of [Micro.blog](https:https//micro.blog). He was very helpful. We discussed directly using the Micro.blog web API’s from Shortcuts. That didn’t sound like much fun to me. Manton mentioned that he had an open source project that I might be interested in. [Snippets](https://github.com/microdotblog/snippets) is an open source Swift implementation of the Micro.blog web API’s. All I had to do was write a wrapper program around Snippets that understood Shortcuts.

So that’s what I did. The [application is also open source](https://github.com/vincode-io/Humboldt) and is named Humboldt. You can download [Humboldt from the App Store](https://apps.apple.com/us/app/humboldt/id1592768206). Humboldt allows you to upload images and posts directly to Micro.blog after you sign in using Humboldt’s Micro.blog authentication flow.

## Zavala Shortcut Support

While I was writing Humboldt, I also was adding Shortcuts support to Zavala 2.0. Zavala’s shortcut support is very extensive and is no way oriented around blogging. But, remember dog-fooding? Blogging directly out of Zavala to my Micro.blog test account became one of the main ways that I tested Shortcuts support.

## Putting It All Together

The [Shortcut I put together](https://www.icloud.com/shortcuts/9539f1b057f7481ca76a8079979a5ac3) has several steps to glue Zavala and Humboldt together. Feel free to take it and customize it to your needs.

The first thing it does is get all the outline data from Zavala. To start it gets the currently selected outline. It uses that to get all the images in the outline and the Markdown Doc version of the outline. It then gets the title of the post by parsing the exported document and saves it to variable to be used later.

The Shortcut then executes a step that can prompt you for the correct Micro.blog blog to post to. Micro.blog supports multiple blogs per user. In the script, I just have this pointing to my personal blog. If you want to use this Shortcut, you will need to change this step.

Uploading the images comes next. For each images uploaded to Micro.blog by Humboldt, a published URL is returned. The exported document is updated with these published URLs by substituting the Zavala image URL in the document for the published URL. The give Micro.blog the information it needs to tie the post to its images.

The top level heading that we parsed out into the title is then stripped from the exported document. Now the document is converted from Markdown to rich text and then from rich text to HTML. Finally the processed document is uploaded to Micro.blog using Humboldt. We use the title variable that we saved early on as a parameter in this step.

## Zavala Isn’t a Blog Editor

Publishing to Micro.blog is a one-way trip. There is no way to edit a published blog post using Zavala. You do have options. You can use a dedicated blog editor or the Micro.blog web interface to update posts.. You can also delete the post and images using the Micro.blog web interface, then post again using the Shortcut.

## Open Platforms FTW

I’d like to thank Manton and the rest of the Micro.blog team for creating a platform that enables this kind of integration. The fact that Snippets was open source made my job much easier.

If you would like to post to your favorite blogging platform from Zavala and need help creating the Shortcut, please get in touch with me at <mo@vincode.io>. I’m busy, but I’ll try to find the time to help you out.