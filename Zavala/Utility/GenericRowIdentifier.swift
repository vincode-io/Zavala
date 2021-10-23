//
//  GenericRowIdentifier.swift
//  Zavala
//
//  Created by Maurice Parker on 10/23/21.
//

import Foundation

class GenericRowIdentifier: NSObject, NSCopying {

	var indexPath: IndexPath
	
	init(indexPath: IndexPath) {
		self.indexPath = indexPath
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		return self
	}
	
}
