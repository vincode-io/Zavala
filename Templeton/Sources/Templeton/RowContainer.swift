//
//  HeadlineContainer.swift
//  
//
//  Created by Maurice Parker on 11/22/20.
//

import Foundation
import SWXMLHash

public protocol RowContainer: class {
	var rows: [TextRow]? { get set }
	func markdown(indentLevel: Int) -> String
	func opml() -> String
}

public extension RowContainer {
	
	func importRows(_ rowIndexers: [XMLIndexer]) {
		var headlines = [TextRow]()
		
		for rowIndexer in rowIndexers {
			let topicPlainText = rowIndexer.element?.attribute(by: "text")?.text ?? ""
			let notePlainText = rowIndexer.element?.attribute(by: "_note")?.text
			
			let headline = TextRow(topicPlainText: topicPlainText, notePlainText: notePlainText)
			headline.importRows(rowIndexer["outline"].all)
			headlines.append(headline)
		}
		
		self.rows = headlines
	}

}
