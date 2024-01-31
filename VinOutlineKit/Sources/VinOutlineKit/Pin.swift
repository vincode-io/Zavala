//
//  Pin.swift
//
//  Created by Maurice Parker on 11/3/21.
//

import Foundation

public extension Notification.Name {
	static let PinWasVisited = Notification.Name(rawValue: "PinWasVisited")
}

public struct Pin: Equatable {
	
	public struct UserInfoKeys {
		public static let pin = "pin"
	}
	
	public let containerIDs: [EntityID]?
	public let documentID: EntityID?
	
	public var containers: [DocumentContainer]? {
		var containers = [DocumentContainer]()
		
		if let containerIDs {
            containers = containerIDs.compactMap { AccountManager.shared.findDocumentContainer($0) }
		}
		
		if containers.isEmpty, let documentID, let container = AccountManager.shared.findDocumentContainer(.allDocuments(documentID.accountID)) {
			containers = [container]
		}
		
		return containers
	}
	
	public var document: Document? {
		guard let documentID else { return nil }
		return AccountManager.shared.findDocument(documentID)
	}
	
	public var userInfo: [AnyHashable: AnyHashable] {
		var userInfo = [AnyHashable: AnyHashable]()
		if let containerIDs {
            userInfo["containerIDs"] = containerIDs.map { $0.userInfo }
		}
		if let documentID {
			userInfo["documentID"] = documentID.userInfo
		}
		return userInfo
	}
	
	public init(containerIDs: [EntityID]? = nil, documentID: EntityID? = nil) {
		self.containerIDs = containerIDs
		self.documentID = documentID
	}

	public init(containers: [DocumentContainer]? = nil, document: Document? = nil) {
        self.containerIDs = containers?.map { $0.id }
		self.documentID = document?.id
	}

	public init(userInfo: Any?) {
		guard let userInfo = userInfo as? [AnyHashable: AnyHashable] else {
			self.containerIDs = nil
			self.documentID = nil
			return
		}
		
		if let userInfos = userInfo["containerIDs"] as? [[AnyHashable : AnyHashable]] {
            self.containerIDs = userInfos.compactMap { EntityID(userInfo: $0) }
		} else {
			self.containerIDs = nil
		}
		
		if let userInfo = userInfo["documentID"] as? [AnyHashable : AnyHashable] {
			self.documentID = EntityID(userInfo: userInfo)
		} else {
			self.documentID = nil
		}
	}
	
}
