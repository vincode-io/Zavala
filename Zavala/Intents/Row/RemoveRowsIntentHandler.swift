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
		
		guard let intentRows = intent.rows else {
			suspend()
			completion(.init(code: .success, userActivity: nil))
			return
		}
		
		var outlines = Set<Outline>()

		let inputRows: [Row] = intentRows
			.compactMap { $0.entityID?.toEntityID() }
			.compactMap {
				if let rowOutline = AccountManager.shared.findDocument($0)?.outline {
					rowOutline.load()
					outlines.insert(rowOutline)
					return rowOutline.findRow(id: $0.rowUUID)
				}
				return nil
			}
		
		let groupedInputRows = Dictionary(grouping: inputRows, by: { $0.outline })
		
		for outline in groupedInputRows.keys {
			if let outline = outline, let deleteRows = groupedInputRows[outline] {
				outline.deleteRows(deleteRows)
			}
		}

		outlines.forEach { $0.unload() }
		suspend()
		completion(.init(code: .success, userActivity: nil))
	}
	
}
