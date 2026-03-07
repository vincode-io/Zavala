//
//  Created by Maurice Parker on 6/12/24.
//

import UIKit
import Markdown
import VinUtility

@MainActor
public struct ImportMarkdownParser: MarkupWalker {
		
	public private(set) var outline: Outline

	private var images: [String:  Data]?

	private var isList = false
	private var parentRowStack = [Row]()
	private var lastHeadingLevel = 0

	public init(account: Account, images: [String:  Data]?) {
		self.outline = Outline(account: account, id: .document(0, UUID().uuidString))
		self.images = images
	}

	nonisolated mutating public func visitHeading(_ heading: Heading) {
		let headingText = heading.plainText
		let headingMarkdown = String(heading.format().trimmingCharacters(in: .newlines).trimmingPrefix(/#+\s*/))
		let headingLevel = heading.level

		MainActor.assumeIsolated {
			if headingLevel == 1 {
				if outline.title == nil {
					outline.title = headingText
				}
			} else {
				let row = Row(outline: outline)
				row.importRow(topicMarkdown: headingMarkdown, noteMarkdown: nil, images: images)

				if headingLevel <= lastHeadingLevel {
					for _ in 0...lastHeadingLevel - headingLevel {
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
			}
		}

		lastHeadingLevel = headingLevel
	}

	nonisolated mutating public func visitParagraph(_ paragraph: Paragraph) {
		guard let formattedParagraph = paragraph.format().trimmed() else { return }

		MainActor.assumeIsolated {
			guard !isList else { return }

			// Unattached paragraphs are assumed to belong to the previous Row
			if let previousRow = parentRowStack.last?.rows.last ?? parentRowStack.last ?? outline.rows.last {
				var newNote = String()

				if let note = previousRow.noteMarkdown(type: .markdown) {
					newNote.append(note)
					newNote.append("\n\n")
					newNote.append(formattedParagraph)
				} else {
					newNote.append(formattedParagraph)
				}

				previousRow.importRow(topicMarkdown: nil, noteMarkdown: newNote, images: images)
			} else {
				let row = Row(outline: outline)
				row.importRow(topicMarkdown: nil, noteMarkdown: formattedParagraph, images: images)
				outline.appendRow(row)
			}
		}
	}

	nonisolated mutating public func visitListItem(_ listItem: ListItem) {
		MainActor.assumeIsolated {
			isList = true
		}

		var topic = String()
		var note = String()

		// Split up and format the Row strings
		for i in 0..<listItem.childCount {

			if let paragraph = listItem.child(at: i) as? Paragraph {

				// The first paragraph is the Topic. Everything else is Notes. Split
				// the lines and trim them so that they don't have a bunch of extraneous
				// leading whitespace.
				if i == 0 {

					let lines = paragraph.format().split(separator: "\n")

					for j in 0..<lines.count {
						let topicLine = String(lines[j]).trimmed()

						topic.append(topicLine ?? "")

						// Don't give the last topic line a newline
						if j < lines.count - 1 {
							topic.append("\n")
						}
					}

				} else {

					// After the first note paragraph, start separating them with newlines
					if i > 1 {
						note.append("\n\n")
					}

					let lines = paragraph.format().split(separator: "\n")

					for j in 0..<lines.count {
						let noteLine = String(lines[j]).trimmed()

						// It looks like the first line in a notes paragraph is
						// blank.
						if noteLine == nil && j == 0 { continue }

						note.append(noteLine ?? "")

						// Don't give the last note line a newline
						if j < lines.count - 1 {
							note.append("\n")
						}
					}
				}

			}

		}

		MainActor.assumeIsolated {
			let row = Row(outline: outline)
			row.importRow(topicMarkdown: topic.isEmpty ? nil : topic, noteMarkdown: note.isEmpty ? nil : note, images: images)

			if let parentRow = parentRowStack.last {
				parentRow.appendRow(row)
			} else {
				outline.appendRow(row)
			}

			parentRowStack.append(row)
		}
		
		descendInto(listItem)

		MainActor.assumeIsolated {
			_ = parentRowStack.removeLast()
			isList = false
		}
	}
	
}
