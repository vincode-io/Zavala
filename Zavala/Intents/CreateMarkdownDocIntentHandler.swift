//
//  CreateMarkdownDocIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 9/28/21.
//

import Intents
import Templeton

class CreateMarkdownDocIntentHandler: NSObject, CreateMarkdownDocIntentHandling {

	func handle(intent: CreateMarkdownDocIntent, completion: @escaping (CreateMarkdownDocIntentResponse) -> Void) {
		guard let intentOutline = intent.outline,
			  let outlineIdentifier = intentOutline.identifier,
			  let id = EntityID(description: outlineIdentifier),
			  let outline = AccountManager.shared.findDocument(id)?.outline else {
				  completion(CreateMarkdownDocIntentResponse(code: .failure, userActivity: nil))
				  return
			  }

		let response = CreateMarkdownDocIntentResponse(code: .success, userActivity: nil)
		response.markdown = outline.markdownDoc()
		completion(response)
	}
	
}
