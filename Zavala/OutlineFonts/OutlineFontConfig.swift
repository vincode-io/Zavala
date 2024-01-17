//
//  OutlineFontConfig.swift
//  Zavala
//
//  Created by Maurice Parker on 3/23/21.
//

import Foundation

struct OutlineFontConfig: Equatable, Hashable {
	
	struct Keys {
		static var name = "name"
		static var size = "size"
		static var secondaryColor = "secondaryColor"
	}
	
	var name: String
	var size: Int
	var secondaryColor: Bool

	var userInfo: [AnyHashable: AnyHashable] {
		var userInfo = [AnyHashable: AnyHashable]()
		userInfo[Keys.name] = name
		userInfo[Keys.size] = size
		userInfo[Keys.secondaryColor] = secondaryColor
		return userInfo
	}
	
	var displayName: String {
		return "\(name) - \(size)"
	}
	
	init(name: String, size: Int, secondaryColor: Bool = false) {
		self.name = name
		self.size = size
		self.secondaryColor = secondaryColor
	}
	
	init?(userInfo: [AnyHashable: AnyHashable]) {
		guard let name = userInfo[Keys.name] as? String,
			  let size = userInfo[Keys.size] as? Int,
			  let secondaryColor = userInfo[Keys.secondaryColor] as? Bool else { return nil }
		
		self.name = name
		self.size = size
		self.secondaryColor = secondaryColor
	}
	
}

