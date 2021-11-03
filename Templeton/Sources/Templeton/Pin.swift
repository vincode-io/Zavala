//
//  Pin.swift
//
//  Created by Maurice Parker on 11/3/21.
//

import Foundation

public struct Pin: Equatable {
	
	public let containerID: EntityID?
	public let documentID: EntityID?
	public let documentTitle: String?
	
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
			"documentID": documentID?.userInfo,
			"documentTitle": documentTitle
		]
	}
	
	public init(containerID: EntityID? = nil, documentID: EntityID? = nil) {
		self.containerID = containerID
		self.documentID = documentID
		self.documentTitle = nil
	}

	public init(container: DocumentContainer? = nil, document: Document? = nil) {
		self.containerID = container?.id
		self.documentID = document?.id
		self.documentTitle = document?.title
	}

	public init(userInfo: Any?) {
		guard let userInfo = userInfo as? [AnyHashable: AnyHashable] else {
			self.containerID = nil
			self.documentID = nil
			self.documentTitle = nil
			return
		}
		
		if let userInfo = userInfo["containerID"] as? [AnyHashable : AnyHashable] {
			self.containerID = EntityID(userInfo: userInfo)
		} else {
			self.containerID = nil
		}
		
		if let userInfo = userInfo["documentID"] as? [AnyHashable : AnyHashable] {
			self.documentID = EntityID(userInfo: userInfo)
		} else {
			self.documentID = nil
		}

		if let documentTitle = userInfo["documentTitle"] as? String{
			self.documentTitle = documentTitle
		} else {
			self.documentTitle = nil
		}
	}
	
}
