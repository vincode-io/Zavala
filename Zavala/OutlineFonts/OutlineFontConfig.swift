//
//  OutlineFontConfig.swift
//  Zavala
//
//  Created by Maurice Parker on 3/23/21.
//

import UIKit

struct OutlineFontConfig: Equatable, Hashable {
	
	struct Keys {
		static var name = "name"
		static var size = "size"
		static var color = "color"
	}
	
	var name: String
	var size: Int
	var color: OutlineFontColor

	var userInfo: [AnyHashable: AnyHashable] {
		var userInfo = [AnyHashable: AnyHashable]()
		userInfo[Keys.name] = name
		userInfo[Keys.size] = size
		userInfo[Keys.color] = color.rawValue
		return userInfo
	}
	
	var displayName: String {
		return "\(name) - \(size)"
	}
	
	init(name: String, size: Int, color: OutlineFontColor) {
		self.name = name
		self.size = size
		self.color = color
	}
	
	init?(userInfo: [AnyHashable: AnyHashable]) {
		guard let name = userInfo[Keys.name] as? String,
			  let size = userInfo[Keys.size] as? Int,
			  let colorRawValue = userInfo[Keys.color] as? Int,
			  let color = OutlineFontColor(rawValue: colorRawValue) else { return nil }
		
		self.name = name
		self.size = size
		self.color = color
	}
	
}

