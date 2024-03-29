//
//  IntentEntityID+.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Foundation
import VinOutlineKit

extension IntentEntityID {
	
	convenience init(_ entityID: EntityID) {
		let description = entityID.description
		self.init(identifier: description, display: description)
	}
	
	func toEntityID() -> EntityID? {
		guard let identifier else { return nil }
		return EntityID(description: identifier)
	}
	
}
