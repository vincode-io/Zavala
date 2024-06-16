//
//  Created by Maurice Parker on 6/12/24.
//

import Foundation
import Markdown
import VinUtility

public struct SimpleRowWalker: MarkupWalker {
		
	public var rows: [Row] {
		return outline?.rows ?? []
	}

	private var outline: Outline?
	private var isList = false
	private var parentRowStack = [Row]()
	private var lastBuiltRow: Row?
	
	public init() {
		self.outline = Outline(id: .document(0, UUID().uuidString))
	}
	
	mutating public func visitText(_ text: Text) {
		guard !isList, let outline else { return }
		
		let row = Row(outline: outline, topicMarkdown: text.format())
		row.detectData()
		outline.appendRow(row)
	}
	
	mutating public func visitLink(_ link: Link) -> () {
		guard !isList, let outline else { return }

		let row = Row(outline: outline, topicMarkdown: link.format())
		row.detectData()
		outline.appendRow(row)
	}
	
	mutating public func visitUnorderedList(_ unorderedList: UnorderedList) {
		isList = true
		
		if let parentRow = lastBuiltRow {
			parentRowStack.append(parentRow)
		}
		
		descendInto(unorderedList)
		
		if !parentRowStack.isEmpty {
			parentRowStack.removeLast()
		}
	}
	
	mutating public func visitListItem(_ listItem: ListItem) {
		guard let outline else { return }
		
		isList = true

		var topic = String()
		
		for i in 0..<listItem.childCount {
			if let paragraph = listItem.child(at: i) as? Paragraph {
				if i > 0 {
					topic.append("\n\n")
				}
				topic.append(paragraph.format().trimmed() ?? "")
			}
		}

		let row = Row(outline: outline, topicMarkdown: topic)
		row.detectData()
		lastBuiltRow = row
		
		if let parentRow = parentRowStack.last {
			parentRow.appendRow(row)
		} else {
			outline.appendRow(row)
		}
		
		descendInto(listItem)
	}
	
}
