//
//  IntentOutline+.swift
//  Zavala
//
//  Created by Maurice Parker on 10/21/21.
//

import Foundation
import VinOutlineKit

extension IntentOutline {
	
	convenience init(_ outline: Outline) {
		self.init(identifier: outline.id.description, display: outline.title ?? "")
		entityID = IntentEntityID(outline.id)
		title = outline.title
		ownerName = outline.ownerName
		ownerEmail = outline.ownerEmail
		ownerURL = outline.ownerURL
		url = outline.id.url
	}
	
}
