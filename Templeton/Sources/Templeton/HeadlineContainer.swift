//
//  HeadlineContainer.swift
//  
//
//  Created by Maurice Parker on 11/22/20.
//

import Foundation
import SWXMLHash

public protocol HeadlineContainer: class {
	var headlines: [Headline]? { get set }
	func markdown(indentLevel: Int) -> String
	func opml() -> String
}

public extension HeadlineContainer {
	
	func importHeadlines(_ headlineIndexers: [XMLIndexer]) {
		var headlines = [Headline]()
		
		for headlineIndexer in headlineIndexers {
			let plainText = headlineIndexer.element?.attribute(by: "text")?.text ?? ""
			let notePlainText = headlineIndexer.element?.attribute(by: "_note")?.text
			
			let headline = Headline(plainText: plainText, notePlainText: notePlainText)
			headline.importHeadlines(headlineIndexer["outline"].all)
			headlines.append(headline)
		}
		
		self.headlines = headlines
	}

}
