//
//  IntentOutline+.swift
//  Zavala
//
//  Created by Maurice Parker on 10/9/21.
//

import Foundation
import Templeton

extension IntentOutline {
	
	convenience init(outline: Outline) {
		self.init(identifier: outline.id.description, display: outline.title ?? "")
		url = outline.id.url
	}
	
}
