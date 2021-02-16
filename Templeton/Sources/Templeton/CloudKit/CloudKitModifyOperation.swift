//
//  CloudKitModifyOperation.swift
//  
//
//  Created by Maurice Parker on 2/15/21.
//

import Foundation

class CloudKitModifyOperation: BaseMainThreadOperation {
	
	init() {
	}
	
	override func run() {
		DispatchQueue.global().async {
			self.processEntityIDs()
		}
	}
	
}

extension CloudKitModifyOperation {
	
	private func processEntityIDs() {
		let queuedIDs: Set<EntityID>?
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
		
		
	}
}
