//
//  RowContainer.swift
//  
//
//  Created by Maurice Parker on 11/22/20.
//

import Foundation
import VinXML

@MainActor
public protocol RowContainer: AnyObject {
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
	
	func importRows(outline: Outline, rowNodes: [VinXML.XMLNode], images: [String:  Data]?) {
		for rowNode in rowNodes {
			let topicMarkdown = rowNode.attributes["text"]
			let noteMarkdown = rowNode.attributes["_note"]
			
			let row = Row(outline: outline)
			row.importRow(topicMarkdown: topicMarkdown, noteMarkdown: noteMarkdown, images: images)

			if rowNode.attributes["_status"] == "checked" {
				row.isComplete = true
			}
			
			appendRow(row)
			
			if let rowNodes = rowNode["outline"] {
				row.importRows(outline: outline, rowNodes: rowNodes, images: images)
			}
		}
	}
	
}
