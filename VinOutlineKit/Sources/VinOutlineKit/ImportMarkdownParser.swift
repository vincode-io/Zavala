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
		self.outline = Outline(account: account, id: .document(account.id.accountID, UUID().uuidString))
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
		guard let formattedParagraph = paragraph.format().trimmed()?.replacingOccurrences(of: "\n", with: " ") else { return }

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
		let lines = listItem.format().split(separator: "\n")
		
		var topic = String()
		for (i, line) in lines.enumerated() {
			if i > 0 {
				topic.append(" ")
			}
			topic.append(String(line).trimmed() ?? "")
		}

		MainActor.assumeIsolated {
			isList = true

			let row = Row(outline: outline)
			row.importRow(topicMarkdown: topic, noteMarkdown: nil, images: images)

			if let parentRow = parentRowStack.last {
				parentRow.appendRow(row)
			} else {
				outline.appendRow(row)
			}

			parentRowStack.append(row)
		}
		
		descendInto(listItem)

		MainActor.assumeIsolated {
			if !parentRowStack.isEmpty {
				parentRowStack.removeLast()
			}
			isList = false
		}
	}

	nonisolated mutating public func visitCodeBlock(_ codeBlock: CodeBlock) {
		var lines = codeBlock.format().split(separator: "\n")
		lines.removeFirst()
		lines.removeLast()

		var note = "`"

		for (i, line) in lines.enumerated() {
			if i > 0 {
				note.append("\n")
			}
			note.append(String(line))
		}

		note.append("`")

		MainActor.assumeIsolated {
			let row = Row(outline: outline)
			row.importRow(topicMarkdown: nil, noteMarkdown: note, images: nil)

			if let parentRow = parentRowStack.last {
				parentRow.appendRow(row)
			} else {
				outline.appendRow(row)
			}
		}

	}

}
