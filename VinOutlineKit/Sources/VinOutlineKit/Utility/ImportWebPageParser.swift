//
//  ImportWebPageParser.swift
//  VinOutlineKit
//
//  Created by Maurice Parker on 8/5/26.
//

import UIKit
import UniformTypeIdentifiers
import VinUtility
import VinXML

/// Walks the readable HTML content produced by Readability (parsed into a VinXML DOM) and builds an
/// Outline from it, mirroring the mapping used by `ImportMarkdownParser`:
///
/// - `<h1>`–`<h6>` become topic rows, nested by heading level.
/// - `<ul>`/`<ol>`/`<li>` become topic rows, nested by list depth.
/// - Block text (`<p>`, `<blockquote>`, …) becomes a Note on the previous topic row, with consecutive
///   blocks concatenated until the next topic. Leading text with no preceding topic produces an
///   empty topic row whose Note holds that content.
/// - Inline formatting (links, bold, italics, inline code, highlight) and images are preserved by
///   emitting markdown that `Row.importRow(topicMarkdown:noteMarkdown:images:)` understands.
@MainActor
public final class ImportWebPageParser {

	public let outline: Outline

	/// Downloaded image data keyed by the `src` attribute value as it appears in the content HTML.
	private let sourceImages: [String: Data]
	/// The page URL, used to resolve relative links and image sources to absolute URLs.
	private let baseURL: URL?

	/// Image data keyed by the generated UUID referenced from the markdown we emit. Accumulated as we
	/// walk and handed to `Row.importRow` so it can resolve `![](uuid.png)` references.
	private var images = [String: Data]()

	private var parentRowStack = [Row]()
	private var lastHeadingLevel = 0
	private var headingRowIDs = Set<String>()
	private var paragraphRowIDs = Set<String>()

	/// Characters that VinMarkdown's `InlineMarkdownParser` treats as literals and whose escaping
	/// backslashes it strips on the way in. Escaping only these keeps plain article text from being
	/// misread as formatting while leaving no stray backslashes behind.
	private static let markdownLiterals: Set<Character> = ["\\", "*", "_", "`", "{", "}", "[", "]", "(", ")", "#", "+", "-", ".", "!"]

	public init(account: Account, baseURL: URL?, sourceImages: [String: Data]) {
		self.outline = Outline(account: account, id: .document(account.id.accountID, UUID().uuidString))
		self.baseURL = baseURL
		self.sourceImages = sourceImages
	}

	/// Parses the given readable content HTML and populates `outline`.
	public func parse(contentHTML: String) {
		guard let document = try? VinXML.XMLDocument(html: contentHTML, caseSensitive: false),
			  let root = document.root else {
			return
		}
		visitBlock(root)
	}

}

// MARK: - Block level

private extension ImportWebPageParser {

	func visitChildren(of node: VinXML.XMLNode) {
		for child in node.childNodes {
			visitBlock(child)
		}
	}

	func visitBlock(_ node: VinXML.XMLNode) {
		switch node.type {
		case .TextNode:
			// Stray text directly inside a block container becomes a Note on the previous topic.
			let text = escapeMarkdown(collapseWhitespace(node.stringValue)).trimmingCharacters(in: .whitespacesAndNewlines)
			appendNote(text)
			return
		case .ElementNode:
			break
		default:
			return
		}

		guard let name = node.name?.lowercased() else { return }

		switch name {
		case "h1", "h2", "h3", "h4", "h5", "h6":
			visitHeading(node, level: Int(name.dropFirst()) ?? 1)
		case "p", "blockquote":
			appendNote(renderInline(node).trimmingCharacters(in: .whitespacesAndNewlines))
		case "ul", "ol":
			visitList(node)
		case "li":
			visitListItem(node)
		case "pre":
			visitCodeBlock(node)
		case "figcaption":
			appendNote(renderInline(node).trimmingCharacters(in: .whitespacesAndNewlines))
		case "img":
			appendNote(imageMarkdown(for: node))
		case "table":
			// Tables have no outline equivalent; flatten their text into a Note.
			appendNote(renderInline(node).trimmingCharacters(in: .whitespacesAndNewlines))
		case "html", "body", "figure", "div", "section", "article", "main", "header", "footer",
			 "aside", "details", "summary", "dl", "dt", "dd":
			// Structural containers we unwrap to get at their block content.
			visitChildren(of: node)
		case "hr", "head", "title", "meta", "link", "script", "style", "noscript",
			 "nav", "form", "button", "input", "select", "textarea", "svg", "iframe", "video", "audio":
			// No meaningful outline content.
			return
		default:
			if node.childNodes.contains(where: { $0.type == .ElementNode }) {
				visitChildren(of: node)
			} else {
				appendNote(renderInline(node).trimmingCharacters(in: .whitespacesAndNewlines))
			}
		}
	}

	func visitHeading(_ node: VinXML.XMLNode, level: Int) {
		let topicMarkdown = renderInline(node).trimmingCharacters(in: .whitespacesAndNewlines)
		guard !topicMarkdown.isEmpty else { return }

		let row = Row(outline: outline)
		row.importRow(topicMarkdown: topicMarkdown, noteMarkdown: nil, images: images)

		if level <= lastHeadingLevel {
			for _ in 0...(lastHeadingLevel - level) {
				if !parentRowStack.isEmpty {
					parentRowStack.removeLast()
				}
			}
		}

		if let parentRow = parentRowStack.last {
			parentRow.appendRow(row)
		} else {
			outline.appendRow(row)
		}

		parentRowStack.append(row)
		headingRowIDs.insert(row.id)
		lastHeadingLevel = level
	}

	func visitList(_ node: VinXML.XMLNode) {
		for child in node.childNodes where child.name?.lowercased() == "li" {
			visitListItem(child)
		}
	}

	func visitListItem(_ node: VinXML.XMLNode) {
		// The item's own inline content becomes the topic; nested lists become child rows.
		let topicMarkdown = renderInline(node).trimmingCharacters(in: .whitespacesAndNewlines)
		let nestedLists = node.childNodes.filter { $0.name?.lowercased() == "ul" || $0.name?.lowercased() == "ol" }

		guard !topicMarkdown.isEmpty || !nestedLists.isEmpty else { return }

		let row = Row(outline: outline)
		row.importRow(topicMarkdown: topicMarkdown, noteMarkdown: nil, images: images)

		if let parentRow = parentRowStack.last {
			parentRow.appendRow(row)
		} else {
			outline.appendRow(row)
		}

		parentRowStack.append(row)
		for list in nestedLists {
			visitList(list)
		}
		if !parentRowStack.isEmpty {
			parentRowStack.removeLast()
		}
	}

	func visitCodeBlock(_ node: VinXML.XMLNode) {
		guard let code = node.content, !code.isEmpty else { return }
		appendNote("`\(code)`")
	}

	/// Attaches note content to the previous topic row, concatenating consecutive blocks. When there
	/// is no qualifying previous topic (e.g. content before the first heading), a topicless row is
	/// created to hold the Note.
	func appendNote(_ markdown: String) {
		guard !markdown.isEmpty else { return }

		let previousRow = parentRowStack.last?.rows.last ?? parentRowStack.last ?? outline.rows.last
		if let previousRow, headingRowIDs.contains(previousRow.id) || paragraphRowIDs.contains(previousRow.id) {
			var newNote = String()
			if let note = previousRow.noteMarkdown(type: .md), !note.isEmpty {
				newNote.append(note)
				newNote.append("\n\n")
				newNote.append(markdown)
			} else {
				newNote.append(markdown)
			}
			previousRow.importRow(topicMarkdown: nil, noteMarkdown: newNote, images: images)
		} else {
			let row = Row(outline: outline)
			row.importRow(topicMarkdown: nil, noteMarkdown: markdown, images: images)
			paragraphRowIDs.insert(row.id)

			if let parentRow = parentRowStack.last {
				parentRow.appendRow(row)
			} else {
				outline.appendRow(row)
			}
		}
	}

}

// MARK: - Inline level

private extension ImportWebPageParser {

	/// Renders a node's inline content to markdown, walking text runs and inline elements in order.
	/// Nested lists are skipped here because they are handled as child rows.
	func renderInline(_ node: VinXML.XMLNode) -> String {
		var result = String()
		for child in node.childNodes {
			switch child.type {
			case .TextNode:
				result.append(escapeMarkdown(collapseWhitespace(child.stringValue)))
			case .ElementNode:
				result.append(renderInlineElement(child))
			default:
				break
			}
		}
		return result
	}

	func renderInlineElement(_ node: VinXML.XMLNode) -> String {
		guard let name = node.name?.lowercased() else { return "" }

		switch name {
		case "a":
			let inner = renderInline(node)
			guard !inner.isEmpty else { return "" }
			if let href = node.attributes["href"], let absolute = absoluteURLString(href) {
				return "[\(inner)](\(absolute))"
			}
			return inner
		case "strong", "b":
			let inner = renderInline(node)
			return inner.isEmpty ? "" : "**\(inner)**"
		case "em", "i", "cite":
			let inner = renderInline(node)
			return inner.isEmpty ? "" : "*\(inner)*"
		case "mark":
			let inner = renderInline(node)
			return inner.isEmpty ? "" : "==\(inner)=="
		case "code", "kbd", "samp", "tt":
			guard let code = node.content, !code.isEmpty else { return "" }
			return "`\(code)`"
		case "br":
			return " "
		case "img":
			return imageMarkdown(for: node)
		case "ul", "ol", "li":
			// Lists are block-level; they are handled by the block walker, not inline.
			return ""
		case "script", "style", "svg":
			return ""
		default:
			// Unwrap unknown inline containers (span, small, sub, sup, abbr, u, …).
			return renderInline(node)
		}
	}

	/// Registers a downloaded image and returns the markdown reference for it, or an empty string if
	/// the image wasn't available.
	func imageMarkdown(for node: VinXML.XMLNode) -> String {
		guard let source = node.attributes["src"] ?? node.attributes["data-src"],
			  let data = sourceImages[source] else {
			return ""
		}
		let uuid = UUID().uuidString
		images[uuid] = data
		return "![](\(uuid).png)"
	}

	func collapseWhitespace(_ string: String?) -> String {
		guard let string else { return "" }
		return string.replacing(/[ \t\n\r\u{0C}]+/, with: " ")
	}

	func escapeMarkdown(_ string: String) -> String {
		var result = String()
		result.reserveCapacity(string.count)
		for character in string {
			if Self.markdownLiterals.contains(character) {
				result.append("\\")
			}
			result.append(character)
		}
		return result
	}

	func absoluteURLString(_ href: String) -> String? {
		let trimmed = href.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return nil }
		if let baseURL, let resolved = URL(string: trimmed, relativeTo: baseURL)?.absoluteURL {
			return resolved.absoluteString
		}
		return trimmed
	}

}
