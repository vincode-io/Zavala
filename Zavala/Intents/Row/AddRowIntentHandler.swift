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
		
		let row = outline.createRow(rowContainer: rowContainer,
									destination: intent.destination.toRowDestination(),
									topic: intent.rowTopic,
									note: intent.rowNote)
		
		suspend()
		let response = AddRowIntentResponse(code: .success, userActivity: nil)
		response.row = IntentEntityID(entityID: row.entityID, display: nil)
		completion(response)
	}
	
}
