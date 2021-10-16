//
//  ImportIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/8/21.
//

import Intents
import Templeton

class ImportIntentHandler: NSObject, ZavalaIntentHandler, ImportIntentHandling {
	
	func resolveInputFile(for intent: ImportIntent, with completion: @escaping (ImportInputFileResolutionResult) -> Void) {
		guard let file = intent.inputFile, !file.data.isEmpty else {
			completion(.unsupported(forReason: .required))
			return
		}
		completion(.success(with: file))
	}
	
	func resolveImportType(for intent: ImportIntent, with completion: @escaping (ImportImportTypeResolutionResult) -> Void) {
		guard intent.importType != .unknown else {
			completion(.unsupported(forReason: .required))
			return
		}
		completion(.success(with: intent.importType))
	}
	
	func resolveAccountType(for intent: ImportIntent, with completion: @escaping (ImportAccountTypeResolutionResult) -> Void) {
		guard intent.accountType != .unknown else {
			completion(.unsupported(forReason: .required))
			return
		}
		completion(.success(with: intent.accountType))
	}
	
	func handle(intent: ImportIntent, completion: @escaping (ImportIntentResponse) -> Void) {
		resume()
		let acctType = intent.accountType == .onMyDevice ? AccountType.local : AccountType.cloudKit
		guard let account = AccountManager.shared.findAccount(accountType: acctType), let data = intent.inputFile?.data else {
			suspend()
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		var images = [String:  Data]()
		if let intentImages = intent.inputImages {
			for intentImage in intentImages {
				let imageUUID = String(intentImage.filename.prefix(while: { $0 != "." }))
				images[imageUUID] = intentImage.data
			}
		}
		
		let doc = account.importOPML(data, tag: nil, images: images)
		
		suspend()
		let response = ImportIntentResponse(code: .success, userActivity: nil)
		response.outlineEntityID = IntentEntityID(entityID: doc.id, display: doc.title)
		completion(response)
	}
	
}
