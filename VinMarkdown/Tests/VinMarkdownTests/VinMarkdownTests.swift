//
//  VinMarkdownTests.swift
//

import Testing
import Foundation
@testable import VinMarkdown

// MARK: - Markdown to Rich Text Tests

@Test func testPlainText() {
	let testString = "Test plain text"
	let compareString = "[Test plain text](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testLiterals() {
	let testString = "Test \\*\\* \\_\\_ and \\* \\_ in string"
	let compareString = "[Test ** __ and * _ in string](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	// no round-trip test because conversion is lossy (literals aren't strictly needed)
}

@Test func testBareLiterals() {
	let testString = "Test * and _ in string"
	let compareString = "[Test * and _ in string](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testSpanWithBareLiterals() {
	let testString = "Test for _span that contains _ and * literals_"
	let compareString = "[Test for ](    )[span that contains _ and * literals]( I  )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testTabsWithBareLiterals() {
	let testString = "\t*\t*\t*\n\t_\t_\t_"
	let compareString = "[\\t*\\t*\\t*\\n\\t_\\t_\\t_](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testUnterminatedMarkers() {
	let testString = "Test * unterminated _ markers and \\*\\* _ escapes"
	let compareString = "[Test * unterminated _ markers and ** _ escapes](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	// No round-trip: escaped markers become bare after parse
}

@Test func testMiddleMarkers() {
	let testString = "Test un_frigging_believable"
	let compareString = "[Test un](    )[frigging]( I  )[believable](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testLiteralsInSpan() {
	let testString = "Test _literals\\_in\\_text span_"
	let compareString = "[Test ](    )[literals_in_text span]( I  )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testSymbolsInSpan() {
	let testString = "Test **span with ⌘ and ⚠️ symbols**"
	let compareString = "[Test ](    )[span with ⌘ and ⚠️ symbols](B   )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testSymbolsAndLiterals() {
	let testString = "Test ¯\\\\\\_(ツ)\\_/¯"
	let compareString = "[Test ¯\\_(ツ)_/¯](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testStylesEmbedded() {
	let testString = "**Test _emphasis_ embedded** and _Test **strong** embedded_"
	let compareString = "[Test ](B   )[emphasis](BI  )[ embedded](B   )[ and ](    )[Test ]( I  )[strong](BI  )[ embedded]( I  )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testStylesEmbeddedWeirdly() {
	let testString = "Test **strong _and** emphasis_ embedded"
	let compareString = "[Test ](    )[strong ](B   )[and](BI  )[ emphasis]( I  )[ embedded](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testStylesAcrossLines() {
	let testString = "Test the _beginning of a **span\nthat** continues on next line._ Because\n**Markdown** is a visual specfication."
	let compareString = "[Test the ](    )[beginning of a ]( I  )[span\\nthat](BI  )[ continues on next line.]( I  )[ Because\\n](    )[Markdown](B   )[ is a visual specfication.](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testStylesAcrossLineBreaks() {
	let testString = "Test _emphasis\n\nthat will not span_ lines."
	let compareString = "[Test _emphasis\\n\\nthat will not span_ lines.](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
}

@Test func testBlankSpans() {
	let testString = "Test **this.****\n\n**"
	let compareString = "[Test ](    )[this.](B   )[**\\n\\n**](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
}

@Test func testStylesWithLiterals() {
	let testString = "Test **\\*\\*strong with literals\\*\\*** and _\\_emphasis too\\__"
	let compareString = "[Test ](    )[**strong with literals**](B   )[ and ](    )[_emphasis too_]( I  )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testBasicLinks() {
	let testString = "Test [inline links](https://iconfactory.com) and automatic links like <https://daringfireball.net/projects/markdown/syntax>"
	let compareString = "[Test ](    )[inline links](    )<https://iconfactory.com>[ and automatic links like ](    )[https://daringfireball.net/projects/markdown/syntax](    )<https://daringfireball.net/projects/markdown/syntax>"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testOtherLinks() {
	let testString = "Test <zippy@pinhead.com> <tel:867-5309> <ssh:l33t@daringfireball.net> <dict://tot>"
	let compareString = "[Test ](    )[zippy@pinhead.com](    )<mailto:zippy@pinhead.com>[ ](    )[tel:867-5309](    )<tel:867-5309>[ ](    )[ssh:l33t@daringfireball.net](    )<ssh:l33t@daringfireball.net>[ ](    )[dict://tot](    )<dict://tot>"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testAutomaticLinksWithUnterminatedMarkers() {
	let testString = "Test <https://music.apple.com/us/album/egg-man/721276795?i=721277066&uo=4&app=itunes&at=10l4G7&ct=STREAMER_MAC>"
	let compareString = "[Test ](    )[https://music.apple.com/us/album/egg-man/721276795?i=721277066&uo=4&app=itunes&at=10l4G7&ct=STREAMER_MAC](    )<https://music.apple.com/us/album/egg-man/721276795?i=721277066&uo=4&app=itunes&at=10l4G7&ct=STREAMER_MAC>"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testAttributeLinksWithoutEscaping() {
	let url = URL(string: "https://music.apple.com/us/album/*/721276795?i=721277066&uo=4&app=itunes&at=10l4G7&ct=STREAMER_MAC")!

	let attrTestString = NSMutableAttributedString(string: "")
	let bareLinkString = NSAttributedString(string: url.absoluteString, attributes: [.link: url])
	attrTestString.append(bareLinkString)
	let spacerString = NSAttributedString(string: " ")
	attrTestString.append(spacerString)
	let namedLinkString = NSAttributedString(string: "inline", attributes: [.link: url])
	attrTestString.append(namedLinkString)

	let compareString = "<https://music.apple.com/us/album/*/721276795?i=721277066&uo=4&app=itunes&at=10l4G7&ct=STREAMER_MAC> [inline](https://music.apple.com/us/album/*/721276795?i=721277066&uo=4&app=itunes&at=10l4G7&ct=STREAMER_MAC)"
	#expect(checkRichTextToMarkdown(attrTestString, compareString))
}

@Test func testAutomaticLinksWithMarkers() {
	let testString = "Test <https://daringfireball.net/2020/02/my_2019_apple_report_card>"
	let compareString = "[Test ](    )[https://daringfireball.net/2020/02/my_2019_apple_report_card](    )<https://daringfireball.net/2020/02/my_2019_apple_report_card>"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testInlineLinksWithMarkers() {
	let testString = "Test **[w\\_oo\\_t](https://daringfireball.net/2020/02/my_2019_apple_report_card)**"
	let compareString = "[Test ](    )[w_oo_t](B   )<https://daringfireball.net/2020/02/my_2019_apple_report_card>"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testIgnoreListMarker() {
	let testString = "* One **item**\n * Two\n  * _Three_\n   * Four\n*\tFive\n *     Six\n\t*\tSeven"
	let compareString = "[* One ](    )[item](B   )[\\n * Two\\n  * ](    )[Three]( I  )[\\n   * Four\\n*\\tFive\\n *     Six\\n\\t*\\tSeven](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testIgnoreHorizontalRules() {
	let testString = "* * *\n***\n*****\n  *  *  *  \n*** ***\n_ _ _\n___\n_____\n  _ _ _ \n___ ___\n---\n"
	let compareString = "[* * *\\n***\\n*****\\n  *  *  *  \\n*** ***\\n_ _ _\\n___\\n_____\\n  _ _ _ \\n___ ___\\n---\\n](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testForPeopleWhoDoMarkdownWrong() {
	let testString = "Test *single asterisk* and __double underscore__"
	let compareString = "[Test ](    )[single asterisk]( I  )[ and ](    )[double underscore](B   )"
	#expect(checkMarkdownToRichText(testString, compareString))
	// no round-trip test because the wrongs will be righted
}

@Test func testForPlainTextFromHell() {
	let testString = " msiexec /i Code42CrashPlan_n.n.n_Win64.msi\n  CP_ARGS=\"DEPLOYMENT_URL=https://.host:port\n  &DEPLOYMENT_POLICY_TOKEN=0fb12341-246b-448d-b07f-c6573ad5ad02\n  &SSL_WHITELIST=7746278a457e64737094c44eeb2bbc32357ece44\n  &PROXY_URL=http://.host:port/fname.pac\"\n  CP_SILENT=true DEVICE_CLOAKED=false /norestart /qn \n\n"
	let compareString = "[ msiexec /i Code42CrashPlan](    )[n.n.n]( I  )[Win64.msi\\n  CP](    )[ARGS=\"DEPLOYMENT]( I  )[URL=https://.host:port\\n  &DEPLOYMENT](    )[POLICY]( I  )[TOKEN=0fb12341-246b-448d-b07f-c6573ad5ad02\\n  &SSL](    )[WHITELIST=7746278a457e64737094c44eeb2bbc32357ece44\\n  &PROXY]( I  )[URL=http://.host:port/fname.pac\"\\n  CP](    )[SILENT=true DEVICE]( I  )[CLOAKED=false /norestart /qn \\n\\n](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testInlineLinksWithEscapes() {
	let testString = "[\\(opt\\-shift\\-k\\)](https://apple.com)\n"
	let compareString = "[(opt-shift-k)](    )<https://apple.com>[\\n](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
}

@Test func testInlineLinksWithoutEscapes() {
	let testString = "[This (should not break) parsing](https://apple.com)\n"
	let compareString = "[This (should not break) parsing](    )<https://apple.com>[\\n](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
}

@Test func testMarkdownEscapes() {
	let attrTestString = NSMutableAttributedString(string: "my_variable_name = 1;")
	let compareString = "my\\_variable\\_name = 1;"
	#expect(checkRichTextToMarkdown(attrTestString, compareString))
}

@Test func testBackslashEscapes() {
	let testString = "This is two \\\\\\\\ escapes and this is \\\\\\\\\\\\ three and don't break here \\"
	let compareString = "[This is two \\\\ escapes and this is \\\\\\ three and don't break here \\](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

// MARK: - Rich Text to Markdown Tests (Simon Ward)

@Test func testItalic() {
	#if canImport(UIKit)
	let attrString = attributedString("Italic", withTraits: .traitItalic)
	#elseif canImport(AppKit)
	let attrString = attributedString("Italic", withTraits: .italic)
	#endif
	#expect(attrString.markdownRepresentation == "_Italic_")
}

@Test func testBold() {
	#if canImport(UIKit)
	let attrString = attributedString("Bold", withTraits: .traitBold)
	#elseif canImport(AppKit)
	let attrString = attributedString("Bold", withTraits: .bold)
	#endif
	#expect(attrString.markdownRepresentation == "**Bold**")
}

@Test func testBoldItalic() {
	#if canImport(UIKit)
	let attrString = attributedString("Italic Bold", withTraits: [.traitItalic, .traitBold])
	#elseif canImport(AppKit)
	let attrString = attributedString("Italic Bold", withTraits: [.italic, .bold])
	#endif
	#expect(attrString.markdownRepresentation == "**_Italic Bold_**")
}

@Test func testSeparate() {
	let attrString = NSMutableAttributedString(string: "This is italic and this is bold.")
	#if canImport(UIKit)
	applySymbolicTraits(.traitItalic, to: attrString, range: NSRange(location: 8, length: 6))
	applySymbolicTraits(.traitBold, to: attrString, range: NSRange(location: 27, length: 4))
	#elseif canImport(AppKit)
	applySymbolicTraits(.italic, to: attrString, range: NSRange(location: 8, length: 6))
	applySymbolicTraits(.bold, to: attrString, range: NSRange(location: 27, length: 4))
	#endif
	#expect(attrString.markdownRepresentation == "This is _italic_ and this is **bold**.")
}

// MARK: - Inline Code Tests

@Test func testInlineCode() {
	let testString = "Use the `print()` function"
	let compareString = "[Use the ](    )[print()](  C )[ function](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testInlineCodeOnly() {
	let testString = "`code`"
	let compareString = "[code](  C )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testInlineCodeWithSpecialCharacters() {
	let testString = "Test `**not bold** _not italic_` end"
	let compareString = "[Test ](    )[**not bold** _not italic_](  C )[ end](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testInlineCodeAtStart() {
	let testString = "`code` at start"
	let compareString = "[code](  C )[ at start](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testInlineCodeAtEnd() {
	let testString = "at end `code`"
	let compareString = "[at end ](    )[code](  C )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testMultipleInlineCodes() {
	let testString = "Use `foo` and `bar` functions"
	let compareString = "[Use ](    )[foo](  C )[ and ](    )[bar](  C )[ functions](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testInlineCodeEmitFromAttributedString() {
	let attrString = NSMutableAttributedString(string: "Use the print() function")
	attrString.addAttribute(.codeInline, value: true, range: NSRange(location: 8, length: 7))
	#expect(attrString.markdownRepresentation == "Use the `print()` function")
}

@Test func testInlineCodeWithEscapedBacktick() {
	let testString = "Test \\`not code\\` end"
	let compareString = "[Test `not code` end](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
}

@Test func testImageURLWithUnderscores() {
	let url = URL(string: "https://example.com/assets/my_image_file.png")!
	let attrTestString = NSMutableAttributedString(string: "my_image", attributes: [.link: url])
	let compareString = "[my\\_image](https://example.com/assets/my_image_file.png)"
	#expect(checkRichTextToMarkdown(attrTestString, compareString))
}

@Test func testInlineCodeWithBoldAround() {
	let testString = "**bold `code` bold**"
	let compareString = "[bold ](B   )[code](B C )[ bold](B   )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}
// MARK: - Highlight Tests

@Test func testHighlight() {
	let testString = "Use the ==highlighted== text"
	let compareString = "[Use the ](    )[highlighted](   H)[ text](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testHighlightOnly() {
	let testString = "==highlighted=="
	let compareString = "[highlighted](   H)"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testHighlightAtStart() {
	let testString = "==highlighted== at start"
	let compareString = "[highlighted](   H)[ at start](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testHighlightAtEnd() {
	let testString = "at end ==highlighted=="
	let compareString = "[at end ](    )[highlighted](   H)"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testMultipleHighlights() {
	let testString = "Use ==foo== and ==bar== words"
	let compareString = "[Use ](    )[foo](   H)[ and ](    )[bar](   H)[ words](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testHighlightWithBold() {
	let testString = "**bold ==highlighted== bold**"
	let compareString = "[bold ](B   )[highlighted](B  H)[ bold](B   )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testHighlightWithItalic() {
	let testString = "_italic ==highlighted== italic_"
	let compareString = "[italic ]( I  )[highlighted]( I H)[ italic]( I  )"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testHighlightWithCode() {
	let testString = "==highlighted `code` highlighted=="
	let compareString = "[highlighted ](   H)[code](  CH)[ highlighted](   H)"
	#expect(checkMarkdownToRichText(testString, compareString))
	#expect(checkRoundTrip(testString))
}

@Test func testHighlightEmitFromAttributedString() {
	let attrString = NSMutableAttributedString(string: "Use the highlighted text")
	attrString.addAttribute(.textHighlightStyle, value: NSAttributedString.TextHighlightStyle.default, range: NSRange(location: 8, length: 11))
	#expect(attrString.markdownRepresentation == "Use the ==highlighted== text")
}

@Test func testUnterminatedHighlight() {
	let testString = "Test ==unterminated highlight"
	let compareString = "[Test ==unterminated highlight](    )"
	#expect(checkMarkdownToRichText(testString, compareString))
}

