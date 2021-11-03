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
		guard let containerID = containerID else { return nil }
		return AccountManager.shared.findDocumentContainer(containerID)
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
	
	public init(container: DocumentContainer? = nil, document: Document? = nil) {
		self.containerID = container?.id
		self.documentID = document?.id
	}

	public init(userInfo: [AnyHashable: AnyHashable]) {
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
