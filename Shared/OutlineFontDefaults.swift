//
//  OutlineFontDefaults.swift
//  Zavala
//
//  Created by Maurice Parker on 3/21/21.
//

import Foundation

struct OutlineFontDefaults {
	
	var rowFontConfigs = [OutlineFontField: OutlineFontConfig]()
	
	static var defaults: OutlineFontDefaults {
		var defaults = OutlineFontDefaults()
		#if targetEnvironment(macCatalyst)
		defaults.rowFontConfigs[.title] = OutlineFontConfig(name: "SF Pro", size: 26)
		defaults.rowFontConfigs[.tags] = OutlineFontConfig(name: "SF Pro", size: 14)
		defaults.rowFontConfigs[.rowTopic(1)] = OutlineFontConfig(name: "SF Pro", size: 14)
		defaults.rowFontConfigs[.rowNote(1)] = OutlineFontConfig(name: "SF Pro", size: 13)
		defaults.rowFontConfigs[.backlinks] = OutlineFontConfig(name: "SF Pro", size: 12)
		#else
		defaults.rowFontConfigs[.title] = OutlineFontConfig(name: "SF Pro", size: 34)
		defaults.rowFontConfigs[.tags] = OutlineFontConfig(name: "SF Pro", size: 17)
		defaults.rowFontConfigs[.rowTopic(1)] = OutlineFontConfig(name: "SF Pro", size: 17)
		defaults.rowFontConfigs[.rowNote(1)] = OutlineFontConfig(name: "SF Pro", size: 16)
		defaults.rowFontConfigs[.backlinks] = OutlineFontConfig(name: "SF Pro", size: 14)
		#endif
		return defaults
	}
	
	public var userInfo: [String: [AnyHashable: AnyHashable]] {
		var userInfo = [String: [AnyHashable: AnyHashable]]()
		for key in rowFontConfigs.keys {
			userInfo[key.description] = rowFontConfigs[key]!.userInfo
		}
		return userInfo
	}
	
	public init() {}
	
	public init(userInfo: [String: [AnyHashable: AnyHashable]]) {
		userInfo.forEach { (key: String, value: [AnyHashable : AnyHashable]) in
			if let field = OutlineFontField(description: key), let config = OutlineFontConfig(userInfo: value) {
				rowFontConfigs[field] = config
			}
		}
	}
	
}
