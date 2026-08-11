//
//  Created by Maurice Parker on 3/7/26.
//

import Foundation
import Markdown
import VinUtility

@MainActor
public struct SimpleMarkdownParser: MarkupWalker {

	public var rows: [Row] {
		MainActor.assumeIsolated {
			return outline.rows
		}
	}

	private var outline: Outline
	private var isList = false
	private var parentRowStack = [Row]()

	public init() {
		self.outline = Outline(account: nil, id: .document(0, UUID().uuidString))
	}

	nonisolated mutating public func visitText(_ text: Text) {
		let formattedText = text.format()

		MainActor.assumeIsolated {
			guard !isList else { return }

			let row = Row(outline: outline, topicMarkdown: formattedText)
			row.detectData()
			outline.appendRow(row)
		}
	}

	nonisolated mutating public func visitLink(_ link: Link) -> () {
		let formattedLink = link.format()

		MainActor.assumeIsolated {
			guard !isList else { return }

			let row = Row(outline: outline, topicMarkdown: formattedLink)
			row.detectData()
			outline.appendRow(row)
		}
	}

	nonisolated mutating public func visitListItem(_ listItem: ListItem) {
		MainActor.assumeIsolated {
			isList = true
		}

		var topic = String()

		for i in 0..<listItem.childCount {
			if let paragraph = listItem.child(at: i) as? Paragraph {
				if i > 0 {
					topic.append("\n\n")
				}
				topic.append(paragraph.format().trimmed() ?? "")
			}
		}

		MainActor.assumeIsolated {
			let row = Row(outline: outline, topicMarkdown: topic)
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
			isList = false
			if !parentRowStack.isEmpty {
				parentRowStack.removeLast()
			}
		}
	}

}
