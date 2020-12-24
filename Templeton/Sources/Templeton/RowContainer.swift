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
	
	func importHeadlines(_ headlineIndexers: [XMLIndexer]) {
		var headlines = [TextRow]()
		
		for headlineIndexer in headlineIndexers {
			let plainText = headlineIndexer.element?.attribute(by: "text")?.text ?? ""
			let notePlainText = headlineIndexer.element?.attribute(by: "_note")?.text
			
			let headline = TextRow(plainText: plainText, notePlainText: notePlainText)
			headline.importHeadlines(headlineIndexer["outline"].all)
			headlines.append(headline)
		}
		
		self.rows = headlines
	}

}
