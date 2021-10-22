//
//  ImportIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/8/21.
//

import Intents
import Templeton

class ImportIntentHandler: NSObject, ZavalaIntentHandler, ImportIntentHandling {
	
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
		
		guard let outline = account.importOPML(data, tag: nil, images: images).outline else {
			suspend()
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		suspend()
		let response = ImportIntentResponse(code: .success, userActivity: nil)
		response.outline = IntentOutline(outline)
		completion(response)
	}
	
}
