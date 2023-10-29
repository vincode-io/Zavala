//
//  AddRowsIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/12/21.
//

import Intents
import Templeton

class AddRowsIntentHandler: NSObject, ZavalaIntentHandler, AddRowsIntentHandling {
	
	func handle(intent: AddRowsIntent, completion: @escaping (AddRowsIntentResponse) -> Void) {
		resume()
		
		guard let entityID = intent.entityID?.toEntityID(), let outline = AccountManager.shared.findDocument(entityID)?.outline else {
			suspend()
			completion(.init(code: .success, userActivity: nil))
			return
		}
		
		outline.load()
	
		guard let rowContainer = outline.findRowContainer(entityID: entityID), let topics = intent.topics else {
			outline.unload()
			suspend()
			completion(.init(code: .success, userActivity: nil))
			return
		}

		
		let rows = topics.map { Row(outline: outline, topicMarkdown: $0) }
		
		rows.forEach({ $0.detectData() })
		
		switch intent.destination {
		case .insideAtStart:
			outline.createRowsInsideAtStart(rows, afterRowContainer: rowContainer)
		case .insideAtEnd:
			outline.createRowsInsideAtEnd(rows, afterRowContainer: rowContainer)
		case .outside:
			if let afterRow = rowContainer as? Row {
				outline.createRowsOutside(rows, afterRow: afterRow)
			} else {
				outline.unload()
				suspend()
				completion(.init(code: .success, userActivity: nil))
				return
			}
		case .directlyAfter:
			if let afterRow = rowContainer as? Row {
				outline.createRowsDirectlyAfter(rows, afterRow: afterRow)
			} else {
				outline.unload()
				suspend()
				completion(.init(code: .success, userActivity: nil))
				return
			}
		default:
			outline.unload()
			suspend()
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		outline.unload()
		suspend()
		let response = AddRowsIntentResponse(code: .success, userActivity: nil)
		response.rows = rows.map { IntentRow($0) }
		completion(response)
	}
	
}
