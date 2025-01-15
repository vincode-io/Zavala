//
//  OutlineFontDefaults.swift
//  Zavala
//
//  Created by Maurice Parker on 3/21/21.
//

import Foundation

struct OutlineFontDefaults: Equatable {
	
	static var defaults: OutlineFontDefaults {
		var defaults = OutlineFontDefaults()
		#if targetEnvironment(macCatalyst) || canImport(AppKit)
		defaults.rowFontConfigs[.title] = OutlineFontConfig(name: "Helvetica Neue", size: 26, color: .primaryText)
		defaults.rowFontConfigs[.tags] = tagConfigV2
		defaults.rowFontConfigs[.rowNumbering(1)] = OutlineFontConfig(name: "Helvetica Neue", size: 14, color: .secondaryText)
		defaults.rowFontConfigs[.rowTopic(1)] = OutlineFontConfig(name: "Helvetica Neue", size: 14, color: .primaryText)
		defaults.rowFontConfigs[.rowNote(1)] = OutlineFontConfig(name: "Helvetica Neue", size: 13, color: .secondaryText)
		defaults.rowFontConfigs[.backlinks] = OutlineFontConfig(name: "Helvetica Neue", size: 12, color: .secondaryText)
		#else
		defaults.rowFontConfigs[.title] = OutlineFontConfig(name: "Helvetica Neue", size: 34, color: .primaryText)
		defaults.rowFontConfigs[.tags] = tagConfigV2
		defaults.rowFontConfigs[.rowNumbering(1)] = OutlineFontConfig(name: "Helvetica Neue", size: 17, color: .secondaryText)
		defaults.rowFontConfigs[.rowTopic(1)] = OutlineFontConfig(name: "Helvetica Neue", size: 17, color: .primaryText)
		defaults.rowFontConfigs[.rowNote(1)] = OutlineFontConfig(name: "Helvetica Neue", size: 16, color: .secondaryText)
		defaults.rowFontConfigs[.backlinks] = OutlineFontConfig(name: "Helvetica Neue", size: 14, color: .secondaryText)
		#endif
		return defaults
	}
	
	static var tagConfigV1: OutlineFontConfig {
		#if targetEnvironment(macCatalyst) || canImport(AppKit)
		return OutlineFontConfig(name: "Helvetica Neue", size: 14, color: .secondaryText)
		#else
		return OutlineFontConfig(name: "Helvetica Neue", size: 17, color: .secondaryText)
		#endif
	}
	
	static var tagConfigV2: OutlineFontConfig {
		#if targetEnvironment(macCatalyst) || canImport(AppKit)
		return OutlineFontConfig(name: "Helvetica Neue", size: 11, color: .secondaryText)
		#else
		return OutlineFontConfig(name: "Helvetica Neue", size: 14, color: .secondaryText)
		#endif
	}
	
	var rowFontConfigs = [OutlineFontField: OutlineFontConfig]()
	var sortedFields: [OutlineFontField] {
		return rowFontConfigs.keys.sorted(by: { $0.displayOrder < $1.displayOrder })
	}
	
	var deepestNumberingLevel: Int {
		var deepestLevel = 0
		for key in rowFontConfigs.keys {
			if case .rowNumbering(let level) = key {
				if level > deepestLevel {
					deepestLevel = level
				}
			}
		}
		return deepestLevel
	}

	var nextNumberingDefault: (OutlineFontField, OutlineFontConfig)? {
		let level = deepestNumberingLevel
		let nextField = OutlineFontField.rowNumbering(level + 1)
		return (nextField, rowFontConfigs[.rowNumbering(level)]!)
	}
	
	var deepestTopicLevel: Int {
		var deepestLevel = 0
		for key in rowFontConfigs.keys {
			if case .rowTopic(let level) = key {
				if level > deepestLevel {
					deepestLevel = level
				}
			}
		}
		return deepestLevel
	}

	var nextTopicDefault: (OutlineFontField, OutlineFontConfig)? {
		let level = deepestTopicLevel
		let nextField = OutlineFontField.rowTopic(level + 1)
		return (nextField, rowFontConfigs[.rowTopic(level)]!)
	}
	
	var deepestNoteLevel: Int {
		var deepestLevel = 0
		for key in rowFontConfigs.keys {
			if case .rowNote(let level) = key {
				if level > deepestLevel {
					deepestLevel = level
				}
			}
		}
		return deepestLevel
	}

	var nextNoteDefault: (OutlineFontField, OutlineFontConfig)? {
		let level = deepestNoteLevel
		let nextField = OutlineFontField.rowNote(level + 1)
		return (nextField, rowFontConfigs[.rowNote(level)]!)
	}
	
	var userInfo: [String: [AnyHashable: AnyHashable]] {
		var userInfo = [String: [AnyHashable: AnyHashable]]()
		for key in rowFontConfigs.keys {
			userInfo[key.description] = rowFontConfigs[key]!.userInfo
		}
		return userInfo
	}
	
	init() {}
	
	init(userInfo: [String: [AnyHashable: AnyHashable]]) {
		userInfo.forEach { (key: String, value: [AnyHashable : AnyHashable]) in
			if let field = OutlineFontField(description: key), let config = OutlineFontConfig(userInfo: value) {
				rowFontConfigs[field] = config
			}
		}
		
		// Heal any broken user defaults. We were getting a crash that shows someone's was corrupted
		for config in Self.defaults.rowFontConfigs {
			if rowFontConfigs[config.key] == nil {
				rowFontConfigs[config.key] = config.value
			}
		}
	}
	
	static func addSecondaryColorFields(userInfo: [String: [AnyHashable: AnyHashable]]) -> [String: [AnyHashable: AnyHashable]]  {
		var updatedUserInfo = [String: [AnyHashable: AnyHashable]]()
		userInfo.forEach { (key: String, value: [AnyHashable : AnyHashable]) in
			var config = value
			
			if let field = OutlineFontField(description: key), field.isSecondary {
				config[OutlineFontConfig.Keys.color] = OutlineFontColor.secondaryText.rawValue
			} else {
				config[OutlineFontConfig.Keys.color] = OutlineFontColor.primaryText.rawValue
			}
			
			updatedUserInfo[key] = config
		}
		return updatedUserInfo
	}
	
	static func addMissingFontConfigs(userInfo: [String: [AnyHashable: AnyHashable]]) -> [String: [AnyHashable: AnyHashable]] {
		let defaults = OutlineFontDefaults.defaults

		var updatedUserInfo = [String: [AnyHashable: AnyHashable]]()

		defaults.rowFontConfigs.keys.forEach { field in
			if userInfo[field.description] == nil {
				updatedUserInfo[field.description] = defaults.rowFontConfigs[field]!.userInfo
			} else {
				updatedUserInfo[field.description] = userInfo[field.description]
			}
		}
		
		return updatedUserInfo
	}
	
	static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.rowFontConfigs == rhs.rowFontConfigs
	}
	
}
