//
//  AddRowIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/12/21.
//

import Intents
import Templeton

class AddRowIntentHandler: NSObject, ZavalaIntentHandler, AddRowIntentHandling {

	func resolveDestination(for intent: AddRowIntent, with completion: @escaping (AddRowDestinationResolutionResult) -> Void) {
		guard intent.destination != .unknown else {
			completion(.unsupported(forReason: .required))
			return
		}
		completion(.success(with: intent.destination))
	}
	
	func resolveRowTopic(for intent: AddRowIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let rowTopic = intent.rowTopic else {
			completion(.notRequired())
			return
		}
		completion(.success(with: rowTopic))
	}
	
	func resolveRowNote(for intent: AddRowIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let rowNote = intent.rowNote else {
			completion(.notRequired())
			return
		}
		completion(.success(with: rowNote))
	}
	
	func handle(intent: AddRowIntent, completion: @escaping (AddRowIntentResponse) -> Void) {
		resume()
		
		guard let entityID = intent.outlineOrRow?.toEntityID(), let rowContainer = AccountManager.shared.findRowContainer(entityID), let outline = rowContainer.outline else {
			suspend()
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		let row = Row(outline: outline, topicPlainText: intent.rowTopic, notePlainText: intent.rowNote)
		
		switch intent.destination {
		case .insideAtStart:
			outline.createRowInsideAtStart(row, afterRowContainer: rowContainer)
		case .insideAtEnd:
			outline.createRowInsideAtEnd(row, afterRowContainer: rowContainer)
		case .outside:
			if let afterRow = rowContainer as? Row {
				outline.createRowOutside(row, afterRow: afterRow)
			} else {
				suspend()
				completion(.init(code: .success, userActivity: nil))
				return
			}
		case .directlyAfter:
			if let afterRow = rowContainer as? Row {
				outline.createRowDirectlyAfter(row, afterRow: afterRow)
			} else {
				suspend()
				completion(.init(code: .success, userActivity: nil))
				return
			}
		default:
			suspend()
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		suspend()
		let response = AddRowIntentResponse(code: .success, userActivity: nil)
		response.row = IntentEntityID(entityID: row.entityID, display: nil)
		completion(response)
	}
	
}
