//
//  IntentEntityID+.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Foundation

import Templeton

extension IntentEntityID {
	
	convenience init(entityID: EntityID, display: String?) {
		self.init(identifier: entityID.description, display: display ?? entityID.description)
		url = entityID.url
	}
	
}
