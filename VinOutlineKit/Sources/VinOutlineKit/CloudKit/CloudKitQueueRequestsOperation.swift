//
//  CloudKitQueueRequestsOperation.swift
//  
//
//  Created by Maurice Parker on 2/15/21.
//

import Foundation
import VinUtility

class CloudKitQueueRequestsOperation: BaseMainThreadOperation {
	
	let requests: Set<CloudKitActionRequest>
	
	init(requests: Set<CloudKitActionRequest>) {
		self.requests = requests
	}
	
	override func run() {
		DispatchQueue.global().async {
			self.processRequests()
		}
	}
	
}

// MARK: Helpers

private extension CloudKitQueueRequestsOperation {
	
	func processRequests() {
		let queuedRequests: Set<CloudKitActionRequest>
		if let fileData = try? Data(contentsOf: CloudKitActionRequest.actionRequestFile) {
			let decoder = PropertyListDecoder()
			if let decodedRequests = try? decoder.decode(Set<CloudKitActionRequest>.self, from: fileData) {
				queuedRequests = decodedRequests
			} else {
				queuedRequests = Set<CloudKitActionRequest>()
			}
		} else {
			queuedRequests = Set<CloudKitActionRequest>()
		}

		let mergedRequests = queuedRequests.union(requests)
		CloudKitActionRequest.save(requests: mergedRequests)

		DispatchQueue.main.async {
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}
