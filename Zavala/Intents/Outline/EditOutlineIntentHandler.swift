//
//  EditOutlineIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/22/21.
//

import Intents
import Templeton

class EditOutlineIntentHandler: NSObject, ZavalaIntentHandler, EditOutlineIntentHandling {

	func resolveTitle(for intent: EditOutlineIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let title = intent.title else {
			completion(.notRequired())
			return
		}
		completion(.success(with: title))
	}
	
	func resolveOwnerName(for intent: EditOutlineIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let ownerName = intent.ownerName else {
			completion(.notRequired())
			return
		}
		completion(.success(with: ownerName))
	}
	
	func resolveOwnerEmail(for intent: EditOutlineIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let ownerEmail = intent.ownerEmail else {
			completion(.notRequired())
			return
		}
		completion(.success(with: ownerEmail))
	}
	
	func resolveOwnerURL(for intent: EditOutlineIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let ownerURL = intent.ownerURL else {
			completion(.notRequired())
			return
		}
		completion(.success(with: ownerURL))
	}
	
	func handle(intent: EditOutlineIntent, completion: @escaping (EditOutlineIntentResponse) -> Void) {
		resume()
		
		guard let outline = findOutline(intent.outline) else {
				  completion(.init(code: .success, userActivity: nil))
				  return
			  }
		
		switch intent.detail {
		case .title:
			outline.update(title: intent.title)
		case .ownerName:
			outline.update(ownerName: intent.ownerName)
		case .ownerEmail:
			outline.update(ownerEmail: intent.ownerEmail)
		case .ownerURL:
			outline.update(ownerURL: intent.ownerURL)
		default:
			break
		}
		
		suspend()
		
		let response = EditOutlineIntentResponse(code: .success, userActivity: nil)
		response.outline = IntentOutline(outline)
		completion(response)
	}
	
}
