//
//  OPMLImporter.swift
//  
//
//  Created by Maurice Parker on 12/25/20.
//

import Foundation
import SWXMLHash

public protocol OPMLImporter: RowContainer {
	var rows: [Row] { get }
	func importRows(outline: Outline, rowIndexers: [XMLIndexer])
}

public extension OPMLImporter {
	
	func importRows(outline: Outline, rowIndexers: [XMLIndexer]) {
		for rowIndexer in rowIndexers {
			let topicPlainText = rowIndexer.element?.attribute(by: "text")?.text ?? ""
			let notePlainText = rowIndexer.element?.attribute(by: "_note")?.text
			
			let textRow = TextRow(document: .outline(outline), topicPlainText: topicPlainText, notePlainText: notePlainText)

			if rowIndexer.element?.attribute(by: "_status")?.text == "checked" {
				textRow.isComplete = true
			}
			
			appendRow(.text(textRow))
			textRow.importRows(outline: outline, rowIndexers: rowIndexer["outline"].all)
		}
	}
	
}
