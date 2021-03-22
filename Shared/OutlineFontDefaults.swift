//
//  OutlineFontDefaults.swift
//  Zavala
//
//  Created by Maurice Parker on 3/21/21.
//

import Foundation

struct OutlineFontDefaults {
	
	struct RowFontConfig {
		var topicName: String
		var topicSize: Int
		var noteName: String
		var noteSize: Int
	}
	
	var rowFontConfigs = [RowFontConfig]()
	
	static var defaults: OutlineFontDefaults {
		var defaults = OutlineFontDefaults()
		for _ in 0..<6 {
			#if targetEnvironment(macCatalyst)
			defaults.rowFontConfigs.append(RowFontConfig(topicName: "SF Pro", topicSize: 14, noteName: "SF Pro", noteSize: 13))
			#else
			defaults.rowFontConfigs.append(RowFontConfig(topicName: "SF Pro", topicSize: 17, noteName: "SF Pro", noteSize: 16))
			#endif
		}
		return defaults
	}
	
	public var userInfo: [[AnyHashable: AnyHashable]] {
		var userInfo = [[AnyHashable: AnyHashable]]()
		for rowFontConfig in rowFontConfigs {
			var rowConfig = [AnyHashable: AnyHashable]()
			rowConfig["topicName"] = rowFontConfig.topicName
			rowConfig["topicSize"] = rowFontConfig.topicSize
			rowConfig["noteName"] = rowFontConfig.noteName
			rowConfig["noteSize"] = rowFontConfig.noteSize
			userInfo.append(rowConfig)
		}
		return userInfo
	}
	
	public init() {}
	
	public init(userInfo: [[AnyHashable: AnyHashable]]) {
		for config in userInfo {
			let topicName = config["topicName"] as! String
			let topicSize = config["topicSize"] as! Int
			let noteName = config["noteName"] as! String
			let noteSize = config["noteSize"] as! Int
			rowFontConfigs.append(RowFontConfig(topicName: topicName, topicSize: topicSize, noteName: noteName, noteSize: noteSize))
		}
	}
	
}
