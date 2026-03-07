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
				outline.title = headingText
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
	
	nonisolated mutating public func visitUnorderedList(_ unorderedList: UnorderedList) {
		MainActor.assumeIsolated {
			isList = true
		}
			
		descendInto(unorderedList)
			
		MainActor.assumeIsolated {
			isList = false
		}
	}
	
	nonisolated mutating public func visitOrderedList(_ orderedList: OrderedList) {
		MainActor.assumeIsolated {
			isList = true
		}
			
		descendInto(orderedList)
			
		MainActor.assumeIsolated {
			isList = false
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
			_ = parentRowStack.removeLast()
			isList = false
		}
	}
	
}
