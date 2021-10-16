//
//  RowContainer.swift
//  
//
//  Created by Maurice Parker on 11/22/20.
//

import Foundation
import SWXMLHash

public protocol RowContainer {
	var outline: Outline? { get }
	var rows: [Row] { get }
	var rowCount: Int { get }

	func containsRow(_: Row) -> Bool
	func insertRow(_: Row, at: Int)
	func removeRow(_: Row)
	func appendRow(_: Row)
	func firstIndexOfRow(_: Row) -> Int?
}

public extension RowContainer {
	
	func importRows(outline: Outline, rowIndexers: [XMLIndexer], images: [String:  Data]?) {
		for rowIndexer in rowIndexers {
			let topicMarkdown = rowIndexer.element?.attribute(by: "text")?.text ?? ""
			let noteMarkdown = rowIndexer.element?.attribute(by: "_note")?.text
			
			let row = Row(outline: outline)
			row.update(topicMarkdown: topicMarkdown, noteMarkdown: noteMarkdown, images: images)

			if rowIndexer.element?.attribute(by: "_status")?.text == "checked" {
				row.isComplete = true
			}
			
			appendRow(row)
			row.importRows(outline: outline, rowIndexers: rowIndexer["outline"].all, images: images)
		}
	}
	
}
