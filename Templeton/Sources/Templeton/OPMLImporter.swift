//
//  OPMLImporter.swift
//  
//
//  Created by Maurice Parker on 12/25/20.
//

import Foundation
import SWXMLHash

public protocol OPMLImporter: class {
	var rows: [Row]? { get set }
	func importRows(_ rowIndexers: [XMLIndexer])
}

public extension OPMLImporter {
	
	func importRows(_ rowIndexers: [XMLIndexer]) {
		var row = [Row]()
		
		for rowIndexer in rowIndexers {
			let topicPlainText = rowIndexer.element?.attribute(by: "text")?.text ?? ""
			let notePlainText = rowIndexer.element?.attribute(by: "_note")?.text
			
			let textRow = TextRow(topicPlainText: topicPlainText, notePlainText: notePlainText)
			
			if rowIndexer.element?.attribute(by: "_status")?.text == "checked" {
				textRow.isComplete = true
			}
			
			textRow.importRows(rowIndexer["outline"].all)
			row.append(.text(textRow))
		}
		
		self.rows = row
	}
	
}
