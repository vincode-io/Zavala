//
//  CloudKitQueueEntityIDsOperation.swift
//  
//
//  Created by Maurice Parker on 2/15/21.
//

import Foundation

class CloudKitQueueEntityIDsOperation: BaseMainThreadOperation {
	
	let entityIDs: Set<EntityID>
	
	init(entityIDs: Set<EntityID>) {
		self.entityIDs = entityIDs
	}
	
	override func run() {
		DispatchQueue.global().async {
			self.processEntityIDs()
		}
	}
	
}

extension CloudKitQueueEntityIDsOperation {
	
	private func processEntityIDs() {
		let queuedIDs: Set<EntityID>
		if let fileData = try? Data(contentsOf: CloudKitManager.actionRequestFile) {
			let decoder = PropertyListDecoder()
			if let decodedIDs = try? decoder.decode(Set<EntityID>.self, from: fileData) {
				queuedIDs = decodedIDs
			} else {
				queuedIDs = Set<EntityID>()
			}
		} else {
			queuedIDs = Set<EntityID>()
		}

		let mergedIDs = queuedIDs.union(entityIDs)
		
		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary

		if let encodedIDs = try? encoder.encode(mergedIDs) {
			try? encodedIDs.write(to: CloudKitManager.actionRequestFile)
		}
		
		DispatchQueue.main.async {
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
