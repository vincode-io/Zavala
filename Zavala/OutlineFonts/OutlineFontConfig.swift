//
//  OutlineFontConfig.swift
//  Zavala
//
//  Created by Maurice Parker on 3/23/21.
//

import Foundation

struct OutlineFontConfig: Equatable, Hashable {
	
	var name: String
	var size: Int

	var userInfo: [AnyHashable: AnyHashable] {
		var userInfo = [AnyHashable: AnyHashable]()
		userInfo["name"] = name
		userInfo["size"] = size
		return userInfo
	}
	
	var displayName: String {
		return "\(name) - \(size)"
	}
	
	init(name: String, size: Int) {
		self.name = name
		self.size = size
	}
	
	init?(userInfo: [AnyHashable: AnyHashable]) {
		guard let name = userInfo["name"] as? String, let size = userInfo["size"] as? Int else { return nil }
		self.name = name
		self.size = size
	}
	
}

