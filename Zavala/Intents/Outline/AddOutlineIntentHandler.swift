//
//  AddOutlineIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents
import VinOutlineKit

class AddOutlineIntentHandler: NSObject, ZavalaIntentHandler, AddOutlineIntentHandling {

	func resolveAccountType(for intent: AddOutlineIntent, with completion: @escaping (IntentAccountTypeResolutionResult) -> Void) {
		guard intent.accountType != .unknown else {
			completion(.needsValue())
			return
		}
		completion(.success(with: intent.accountType))
	}
	
	func resolveTitle(for intent: AddOutlineIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let title = intent.title else {
			completion(.needsValue())
			return
		}
		completion(.success(with: title))
	}

    func resolveTagNames(for intent: AddOutlineIntent, with completion: @escaping ([INStringResolutionResult]) -> Void) {
		guard let tagNames = intent.tagNames else {
			completion([INStringResolutionResult]())
			return
		}
        completion(tagNames.map({ INStringResolutionResult.success(with: $0) }))
	}

	func handle(intent: AddOutlineIntent, completion: @escaping (AddOutlineIntentResponse) -> Void) {
		resume()
		
		let acctType = intent.accountType == .onMyDevice ? AccountType.local : AccountType.cloudKit
		guard let account = AccountManager.shared.findAccount(accountType: acctType), let title = intent.title else {
			suspend()
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		var tags = [Tag]()
		if let tagNames = intent.tagNames {
            for tagName in tagNames {
                if !tagName.isEmpty {
                    tags.append(account.createTag(name: tagName))
                }
            }
		}
		
		guard let outline = account.createOutline(title: title, tags: tags).outline else {
			suspend()
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		suspend()
		let response = AddOutlineIntentResponse(code: .success, userActivity: nil)
		response.outline = IntentOutline(outline)
		completion(response)
	}
	
}
