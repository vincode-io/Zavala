//
//  RemoveRowsIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/15/21.
//

import Intents
import Templeton

class RemoveRowsIntentHandler: NSObject, ZavalaIntentHandler, RemoveRowsIntentHandling {

	func handle(intent: RemoveRowsIntent, completion: @escaping (RemoveRowsIntentResponse) -> Void) {
		resume()
		
		guard let intentRowEntityIDs = intent.rows else {
			suspend()
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		let inputRows = intentRowEntityIDs.compactMap({ $0.toEntityID() }).compactMap({ AccountManager.shared.findRow($0) })
		let groupedInputRows = Dictionary(grouping: inputRows, by: { $0.outline })
		
		for outline in groupedInputRows.keys {
			if let outline = outline, let deleteRows = groupedInputRows[outline] {
				outline.load()
				outline.deleteRows(deleteRows)
				outline.unload()
			}
		}
		
		suspend()
		completion(.init(code: .success, userActivity: nil))
	}
	
}
