---
layout: single
title: Importing Outlines
permalink: /help/Importing_Outlines.md/
header:
  overlay_image: /assets/images/phone_and_laptop.png
  overlay_filter: 0.5
---



If you are coming to Zavala from another outliner application, you can bring
your data with you if your existing outliner has an OPML, Markdown, or HTML
export function. OPML is the preferred format. It is designed for outlines and
is much more structured than Markdown or HTML.

* How to Start an Import
	* macOS
		* You can use the File menu to start the import.
		* You can drag one or more files onto a Tag collection or the All collection to
import them and associate that Tag with them.
		* You can drag into the Document VIew to import into the selected collection.
	* iOS
		* You can use one of the Import options in the More menu in the Documents view.
		* You can also drag to the Collection Column or Document View the same way that
you can on macOS
* Supported File Types
	* Markdown

	  Zavala does a fairly decent job of importing Markdown considering that Markdown
	  is not an outline format. Importing Markdown will utilize the Notes field for
	  text that isn’t a heading or list. See “Alternate Usage” in
	  [The Notes Field](The_Notes_Field.md) for more information.


	* HTML

	  While Zavala supports importing HTML, it is very hit and miss. The main problem
	  is that so many web pages aren’t actually structured using header and list
	  tags. They are just text formatted using CSS to look like they are. Something
	  that looks like an indented list, may not actually be one in the HTML of the
	  page.

	  Even worse, some pages use JavaScript to generate the text of the page. This is
	  extremely difficult to download and parse without a full web browser and is
	  beyond Zavala’s current capabilities.


	* OPML

	  This is the preferred format in Zavala for input and output. OPML is
	  specifically designed for outline applications and is the best format for
	  transferring outlines between them.

