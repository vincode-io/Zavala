//
//  EditOutlineIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/22/21.
//

import Foundation

import Templeton

class EditOutlineIntentHandler: NSObject, ZavalaIntentHandler, EditOutlineIntentHandling {

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
