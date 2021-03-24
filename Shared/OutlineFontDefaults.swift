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
//		defaults.rowFontConfigs[.tags] = OutlineFontConfig(name: "SF Pro", size: 14)
//		defaults.rowFontConfigs[.rowTopic(1)] = OutlineFontConfig(name: "SF Pro", size: 14)
//		defaults.rowFontConfigs[.rowNote(1)] = OutlineFontConfig(name: "SF Pro", size: 13)
//		defaults.rowFontConfigs[.backlinks] = OutlineFontConfig(name: "SF Pro", size: 12)
		#else
		defaults.rowFontConfigs[.title] = OutlineFontConfig(name: "SF Pro", size: 34)
		defaults.rowFontConfigs[.tags] = OutlineFontConfig(name: "SF Pro", size: 17)
		defaults.rowFontConfigs[.rowTopic(1)] = OutlineFontConfig(name: "SF Pro", size: 17)
		defaults.rowFontConfigs[.rowNote(1)] = OutlineFontConfig(name: "SF Pro", size: 16)
		defaults.rowFontConfigs[.backlinks] = OutlineFontConfig(name: "SF Pro", size: 14)
		#endif
		return defaults
	}
	
	public var userInfo: [[AnyHashable: AnyHashable]: [AnyHashable: AnyHashable]] {
		var userInfo = [[AnyHashable: AnyHashable]: [AnyHashable: AnyHashable]]()
		for key in rowFontConfigs.keys {
			userInfo[key.userInfo] = rowFontConfigs[key]!.userInfo
		}
		return userInfo
	}
	
	public init() {}
	
	public init(userInfo: [[AnyHashable: AnyHashable]: [AnyHashable: AnyHashable]]) {
		userInfo.forEach { (key: [AnyHashable : AnyHashable], value: [AnyHashable : AnyHashable]) in
			if let field = OutlineFontField(userInfo: key), let config = OutlineFontConfig(userInfo: value) {
				rowFontConfigs[field] = config
			}
		}
	}
	
}
