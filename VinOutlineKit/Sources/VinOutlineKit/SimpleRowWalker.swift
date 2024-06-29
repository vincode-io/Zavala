//
//  Created by Maurice Parker on 6/12/24.
//

import Foundation
import Markdown
import VinUtility

@MainActor
public struct SimpleRowWalker: MarkupWalker {
		
	public var rows: [Row] {
		MainActor.assumeIsolated {
			return outline?.rows ?? []
		}
	}

	private var outline: Outline?
	private var isList = false
	private var parentRowStack = [Row]()
	private var lastBuiltRow: Row?
	
	public init() {
		self.outline = Outline(id: .document(0, UUID().uuidString))
	}
	
	nonisolated mutating public func visitText(_ text: Text) {
		let formattedText = text.format()
		
		MainActor.assumeIsolated {
			guard !isList, let outline else { return }

			let row = Row(outline: outline, topicMarkdown: formattedText)
			row.detectData()
			outline.appendRow(row)
		}
	}
	
	nonisolated mutating public func visitLink(_ link: Link) -> () {
		let formattedLink = link.format()
		
		MainActor.assumeIsolated {
			guard !isList, let outline else { return }

			let row = Row(outline: outline, topicMarkdown: formattedLink)
			row.detectData()
			outline.appendRow(row)
		}
	}
	
	nonisolated mutating public func visitUnorderedList(_ unorderedList: UnorderedList) {
		MainActor.assumeIsolated {
			isList = true
			
			if let parentRow = lastBuiltRow {
				parentRowStack.append(parentRow)
			}
		}
			
		descendInto(unorderedList)
			
		MainActor.assumeIsolated {
			if !parentRowStack.isEmpty {
				parentRowStack.removeLast()
			}
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
			guard let outline else { return }

			let row = Row(outline: outline, topicMarkdown: topic)
			row.detectData()
			lastBuiltRow = row
			
			if let parentRow = parentRowStack.last {
				parentRow.appendRow(row)
			} else {
				outline.appendRow(row)
			}
		}
		
		descendInto(listItem)
	}
	
}
