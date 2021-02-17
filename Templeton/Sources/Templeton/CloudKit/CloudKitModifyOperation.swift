//
//  CloudKitModifyOperation.swift
//  
//
//  Created by Maurice Parker on 2/15/21.
//

import Foundation
import CloudKit

class CloudKitModifyOperation: BaseMainThreadOperation {
	
	private var zone: CloudKitOutlineZone
	
	init(zone: CloudKitOutlineZone) {
		self.zone = zone
	}
	
	override func run() {
		guard let account = AccountManager.shared.cloudKitAccount else { return }
		
		var recordsToSave = [CKRecord]()
		var recordIDsToDelete = [CKRecord.ID]()
		var (documentIDs, documentRowIDs) = loadRequests()
		
		guard !documentIDs.isEmpty || !documentRowIDs.isEmpty else { return }
		
		for documentID in documentIDs {
			let id = documentID.documentUUID
			if let document = account.findDocument(documentUUID: id) {
				// Create modify record
			} else {
				// Create delete id
				documentRowIDs.removeValue(forKey: id)
			}
		}
		
	}
	
}

extension CloudKitModifyOperation {
	
	private func loadRequests() -> (CloudKitActionRequest, [String: [CloudKitActionRequest]]) {
		var queuedRequests: Set<CloudKitActionRequest>? = nil
		if let fileData = try? Data(contentsOf: CloudKitActionRequest.actionRequestFile) {
			let decoder = PropertyListDecoder()
			if let decodedRequests = try? decoder.decode(Set<CloudKitActionRequest>.self, from: fileData) {
				queuedRequests = decodedRequests
			}
		}

		var documentRequests = [CloudKitActionRequest]()
		var documentRowRequests = [String: [CloudKitActionRequest]]()
		
		guard !(queuedRequests?.isEmpty ?? true) else { return (documentRequests, documentRowRequests) }
		
		for queuedRequest in queuedRequests! {
			switch queuedRequest {
			case .document:
				documentRequests.append(queuedRequest)
			case .row(_, let documentUUID, _):
				if var rowIDs = documentRowRequests[documentUUID] {
					rowIDs.append(queuedRequest)
					documentRowRequests[documentUUID] = rowIDs
				} else {
					var rowIDs = [CloudKitActionRequest]()
					rowIDs.append(queuedRequest)
					documentRowRequests[documentUUID] = rowIDs
				}
			default:
				fatalError()
			}
		}
		
		return (documentRequests, documentRowRequests)
	}
	
}
