//
//  Outline+AppIntentsForSiri.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import Markdown
import VinOutlineKit

extension Outline {

	/// The Tag used as the Notes domain folder. When an Outline has more than one Tag, the first one alphabetically is used.
	var folderTag: Tag? {
		return tags.min { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
	}

	/// Converts the given text into rows and appends them to the end of the Outline. Each line becomes a row and
	/// Markdown lists become nested rows, the same way pasted text is handled.
	func appendNoteContent(_ content: AttributedString) async {
		let attrString = (try? NSAttributedString(content, including: \.uiKit)) ?? NSAttributedString(content)

		var markdownLines = [String]()
		let fullRange = NSRange(location: 0, length: attrString.length)
		(attrString.string as NSString).enumerateSubstrings(in: fullRange, options: .byLines) { _, lineRange, _, _ in
			markdownLines.append(attrString.attributedSubstring(from: lineRange).markdownRepresentation)
		}

		let document = Markdown.Document(parsing: markdownLines.joined(separator: "\n"))
		var parser = SimpleMarkdownParser()
		parser.visit(document)

		guard !parser.rows.isEmpty else { return }

		load()
		let rows = parser.rows.map { RowGroup($0).attach(to: self) }
		createRowsInsideAtEnd(rows, afterRowContainer: self)
		await unload()
	}

}
