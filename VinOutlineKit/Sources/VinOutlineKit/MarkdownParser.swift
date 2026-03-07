//
//  Created by Maurice Parker on 6/12/24.
//

import UIKit
import Markdown
import VinUtility

@MainActor
public struct MarkdownParser: MarkupWalker {
		
	public private(set) var outline: Outline
	
	private var isList = false
	private var parentRowStack = [Row]()
	private var lastHeadingLevel = 0

	public init() {
		self.outline = Outline(account: nil, id: .document(0, UUID().uuidString))
	}

	public init(account: Account) {
		self.outline = Outline(account: account, id: .document(0, UUID().uuidString))
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
				let row = Row(outline: outline, topicMarkdown: headingMarkdown)
				row.detectData()

				if headingLevel <= lastHeadingLevel {
					for _ in 0...lastHeadingLevel - headingLevel {
						parentRowStack.removeLast()
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
			if let previousRow = outline.rows.last {
				if let note = previousRow.note {
					let newNote = NSMutableAttributedString(attributedString: note)
					newNote.append(NSAttributedString(string: "\n\n"))
					newNote.append(NSMutableAttributedString(markdownRepresentation: formattedParagraph, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]))
					previousRow.note = newNote
				} else {
					previousRow.note = NSMutableAttributedString(markdownRepresentation: formattedParagraph, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
				}
			} else {
				let row = Row(outline: outline, noteMarkdown: formattedParagraph)
				row.detectData()
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
			let row = Row(outline: outline, topicMarkdown: topic.isEmpty ? nil : topic, noteMarkdown: note.isEmpty ? nil : note)
			row.detectData()

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
