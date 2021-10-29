---
Title: Row Metadata Proposal
---



## What is it?

Metadata means “data about data”. Row Metadata is data about a Row. It is useful for providing additional meaning to a row in a structured way. Each Row Metadata item is a key/value pair. For example you could assign some Rows to have a Metadata items that has a key of “Assigned To” and a value of “Bob”. Now you have a way of identifying all Rows that are assigned to Bob.

Some other outliners already support this concept. They call them Columns. In the screenshot below from [SheetPlanner](https://sheetplanner.com) you can see how Columns and Row Metadata are the same thing. The far right column is the same exact example we gave earlier for what Row Metadata was.

![](/assets/images/E0AC7661-235D-45EB-B5EC-E1923A3C8C99.png)￼

## Why call it something different?

For me, I always thought the concept of columns in an outline to be weird. I mean, is it a spreadsheet or an outline? I just couldn’t get my head around the concept until I realized that the columns are really just metadata about a row.

I didn’t want to turn Zavala into something that looks like a spreadsheet, so I decided to show Row Metadata differently than I had seen done in other outliners. I wanted to show it inline, with the text as objects that can be added and deleted with the text.
![](/assets/images/09218938-72BA-4EC4-836B-33637EA8BF18.png)￼
In this screenshot we see some metadata when “Due” is equal to “12/25/2021”. The metadata tracks its place in the text, moving forward and backward as you change the text. You can even type more text after the metadata. There are pro’s and con’s to the approach.

Some positives are that the you don’t have an outline that looks and acts like a spreadsheet if you need to track metadata. This can be a usability advantage especially on a mobile device where spreadsheets just don’t fit very well. You also have a more data density if you are only using a specific type of metadata on some of the Rows. For example if you only have one row in 20 that needs to know Due Date, then you don’t have 19 empty spreadsheet cells.

Spreadsheets do have a usability advantage over this approach. It is easier to scan metadata with your eye if it is all in a straight column.

## What can I do with it?

You can search for it. In Zavala’s search fields you will be able to specify the Row Metadata key you want and the value that you are searching for.

You will be able to use Shortcuts to find and manipulate it. This will enable users to build advanced workflows that fit their specific needs.

You will be able to import it and export it in OPML files. These files will be compatible with [SheetPlanner](https://sheetplanner.com), [OmniOutliner](https://www.omnigroup.com/omnioutliner), and other outliners that support columns or metadata.

## What do you think?

I’ve made some assumptions about how metadata or columns are used. I think it is used fairly rarely, and when it is, it is used moderately.

Not everyone outlines the same way and I could be completely wrong. Please [comment in this thread](https://github.com/vincode-io/Zavala/discussions/131) on GitHub Discussions. I need insight into how this feature will be used so that I can make Zavala’s metadata capabilities the best that they can be.