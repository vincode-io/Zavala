//
//  Pin.swift
//
//  Created by Maurice Parker on 11/3/21.
//

import Foundation

public struct Pin: Equatable {
	public let containerID: EntityID?
	public let documentID: EntityID?
	
	public var container: DocumentContainer? {
		if let containerID = containerID {
			if let container = AccountManager.shared.findDocumentContainer(containerID) {
				return container
			}
		}
		
		if let documentID = documentID {
			return AccountManager.shared.findDocumentContainer(.allDocuments(documentID.accountID))
		}
		
		return nil
	}
	
	public var document: Document? {
		guard let documentID = documentID else { return nil }
		return AccountManager.shared.findDocument(documentID)
	}
	
	public var userInfo: [AnyHashable: AnyHashable] {
		return [
			"containerID": containerID?.userInfo,
			"documentID": documentID?.userInfo
		]
	}
	
	public init(containerID: EntityID? = nil, documentID: EntityID? = nil) {
		self.containerID = containerID
		self.documentID = documentID
	}

	public init(container: DocumentContainer? = nil, document: Document? = nil) {
		self.containerID = container?.id
		self.documentID = document?.id
	}

	public init(userInfo: Any?) {
		guard let userInfo = userInfo as? [AnyHashable: AnyHashable] else {
			containerID = nil
			documentID = nil
			return
		}
		
		if let userInfo = userInfo["containerID"] as? [AnyHashable : AnyHashable] {
			containerID = EntityID(userInfo: userInfo)
		} else {
			containerID = nil
		}
		
		if let userInfo = userInfo["documentID"] as? [AnyHashable : AnyHashable] {
			documentID = EntityID(userInfo: userInfo)
		} else {
			documentID = nil
		}
	}
	
}
