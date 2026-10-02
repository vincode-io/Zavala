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

	/// A plain text version of printList() for apps that can't display rich text, such as messaging apps.
	/// printList() indents nested rows with paragraph styles, which plain text doesn't have, so this indents
	/// with a tab per level instead. Completed rows are marked with a check mark because there's no strikethrough.
	func printListPlainText() -> String {
		load()

		var text = "\(title ?? "")\n"

		func indented(_ string: String, by indent: String) -> String {
			string.split(separator: "\n", omittingEmptySubsequences: false)
				.map { $0.isEmpty ? "" : indent + $0 }
				.joined(separator: "\n")
		}

		func visit(_ row: Row, level: Int) {
			let indent = String(repeating: "\t", count: level)
			let completeMark = row.isComplete ?? false ? "\u{2713}" : nil

			if let topic = row.topic?.string {
				let marker = switch numberingStyle ?? .none {
				case .none:
					completeMark ?? "\u{2022}"
				case .simple:
					[row.simpleNumbering, completeMark].compactMap { $0 }.joined(separator: " ")
				case .decimal:
					[row.decimalNumbering, completeMark].compactMap { $0 }.joined(separator: " ")
				case .legal:
					[row.legalNumbering, completeMark].compactMap { $0 }.joined(separator: " ")
				}

				// The first line follows the marker and any continuation lines line up with it
				let topicLines = topic.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
				text.append("\(indent)\(marker)\t\(topicLines.first ?? "")\n")
				if topicLines.count > 1 {
					text.append(indented(String(topicLines[1]), by: indent + "\t") + "\n")
				}
			}

			if let note = row.note?.string, !note.isEmpty {
				text.append(indented(note, by: indent + "\t") + "\n")
			}

			row.rows.forEach { visit($0, level: level + 1) }
		}

		rows.forEach { visit($0, level: 0) }

		Task {
			await unload()
		}

		return text
	}

}
