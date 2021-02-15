//
//  CloudKitManager.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import Foundation
import CloudKit

public class CloudKitManager {
	
	enum Action {
		case add
		case change
		case delete
	}
	
	struct ActionRequest {
		let action: Action
		let id: EntityID
	}

	private let container: CKContainer = {
		let orgID = Bundle.main.object(forInfoDictionaryKey: "OrganizationIdentifier") as! String
		return CKContainer(identifier: "iCloud.\(orgID).Zavala")
	}()

	private let defaultZone: CloudKitOutlineZone

	init() {
		defaultZone = CloudKitOutlineZone(container: container)
	}
	
	func addRequest(action: Action, id: EntityID) {
		let actionRequest = ActionRequest(action: action, id: id)
		// Now do something with it
	}
	
	func accountDidInitialize(_ account: Account) {
		defaultZone.delegate = CloudKitAcountZoneDelegate(account: account)
	}
	
	func accountWillBeDeleted(_ account: Account) {
		defaultZone.resetChangeToken()
	}
	
}
