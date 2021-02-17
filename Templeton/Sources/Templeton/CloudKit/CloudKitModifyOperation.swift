//
//  CloudKitModifyOperation.swift
//  
//
//  Created by Maurice Parker on 2/15/21.
//

import Foundation
import CloudKit

class CloudKitModifyOperation: BaseMainThreadOperation {

	var modifications = [CKRecordZone.ID: ([CKRecord], [CKRecord.ID])]()

	override func run() {
		guard let account = AccountManager.shared.cloudKitAccount else { return }
		
		var (documentRequests, documentRowRequests) = loadRequests()
		
		guard !documentRequests.isEmpty || !documentRowRequests.isEmpty else { return }
		
		for documentRequest in documentRequests {
			let id = documentRequest.id.documentUUID
			if let document = account.findDocument(documentUUID: id) {
				addSave(document)
			} else {
				addDelete(documentRequest)
				documentRowRequests.removeValue(forKey: id)
			}
		}
		
		// TODO: Add row processing here...
		
		// TODO: Look up zones and send modifies
	}
	
}

extension CloudKitModifyOperation {
	
	private func loadRequests() -> ([CloudKitActionRequest], [String: [CloudKitActionRequest]]) {
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
			switch queuedRequest.id {
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
	
	private func addSave(_ document: Document) {
		guard let outline = document.outline,
			  let zoneName = outline.cloudKitZoneName,
			  let zoneOwner = outline.cloudKitZoneOwner else { return }
		
		let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: zoneOwner)
		let recordID = CKRecord.ID(recordName: outline.id.documentUUID, zoneID: zoneID)
		let record = CKRecord(recordType: CloudKitOutlineZone.CloudKitOutline.recordType, recordID: recordID)
		
		record[CloudKitOutlineZone.CloudKitOutline.Fields.title] = outline.title
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerName] = outline.ownerName
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerEmail] = outline.ownerEmail
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerURL] = outline.ownerURL
		record[CloudKitOutlineZone.CloudKitOutline.Fields.tagNames] = outline.tags.map { $0.name }
		record[CloudKitOutlineZone.CloudKitOutline.Fields.rowOrder] = outline.rowOrder?.map { $0.documentUUID }

		addSave(zoneID, record)
	}
	
	private func addSave(_ zoneID: CKRecordZone.ID, _ record: CKRecord) {
		if let (saves, deletes) = modifications[zoneID] {
			var mutableSaves = saves
			mutableSaves.append(record)
			modifications[zoneID] = (mutableSaves, deletes)
		} else {
			var saves = [CKRecord]()
			saves.append(record)
			let deletes = [CKRecord.ID]()
			modifications[zoneID] = (saves, deletes)
		}
	}
	
	private func addDelete(_ request: CloudKitActionRequest) {
		let zoneID = request.zoneID
		let recordID = CKRecord.ID(recordName: request.id.documentUUID, zoneID: zoneID)
		addDelete(zoneID, recordID)
	}
	
	private func addDelete(_ zoneID: CKRecordZone.ID, _ recordID: CKRecord.ID) {
		if let (saves, deletes) = modifications[zoneID] {
			var mutableDeletes = deletes
			mutableDeletes.append(recordID)
			modifications[zoneID] = (saves, mutableDeletes)
		} else {
			let saves = [CKRecord]()
			var deletes = [CKRecord.ID]()
			deletes.append(recordID)
			modifications[zoneID] = (saves, deletes)
		}
	}
	
}
