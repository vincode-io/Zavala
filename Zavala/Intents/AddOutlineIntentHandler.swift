//
//  AddOutlineIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents
import Templeton

class AddOutlineIntentHandler: NSObject, ZavalaIntentHandler, AddOutlineIntentHandling {

	func resolveAccountType(for intent: AddOutlineIntent, with completion: @escaping (AddOutlineAccountTypeResolutionResult) -> Void) {
		guard intent.accountType != .unknown else {
			completion(.unsupported(forReason: .required))
			return
		}
		completion(.success(with: intent.accountType))
	}
	
	func resolveTitle(for intent: AddOutlineIntent, with completion: @escaping (AddOutlineTitleResolutionResult) -> Void) {
		guard let title = intent.title else {
			completion(.unsupported(forReason: .required))
			return
		}
		completion(.success(with: title))
	}
	
	func resolveTagName(for intent: AddOutlineIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let tagName = intent.tagName else {
			completion(.notRequired())
			return
		}
		completion(.success(with: tagName))
	}

	func handle(intent: AddOutlineIntent, completion: @escaping (AddOutlineIntentResponse) -> Void) {
		resume()
		
		let acctType = intent.accountType == .onMyDevice ? AccountType.local : AccountType.cloudKit
		guard let account = AccountManager.shared.findAccount(accountType: acctType), let title = intent.title else {
			suspend()
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		var tag: Tag? = nil
		if let tagName = intent.tagName, !tagName.isEmpty {
			tag = account.createTag(name: tagName)
		}
		
		let _ = account.createOutline(title: title, tag: tag)
		
		suspend()
		completion(AddOutlineIntentResponse(code: .success, userActivity: nil))
	}
	
}
