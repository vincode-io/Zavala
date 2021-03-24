//
//  OutlineFontField.swift
//  Zavala
//
//  Created by Maurice Parker on 3/23/21.
//

import Foundation

enum OutlineFontField: Hashable {
	case title
	case tags
	case rowTopic(Int) // Level
	case rowNote(Int) // Level
	case backlinks
	
	var userInfo: [AnyHashable: AnyHashable] {
		var userInfo = [AnyHashable: AnyHashable]()
		switch self {
		case .title:
			userInfo["type"] = "title"
		case .tags:
			userInfo["type"] = "tags"
		case .rowTopic(let level):
			userInfo["type"] = "rowTopic"
			userInfo["level"] = level
		case .rowNote(let level):
			userInfo["type"] = "rowNote"
			userInfo["level"] = level
		case .backlinks:
			userInfo["type"] = "backlinks"
		}
		return userInfo
	}

	init?(userInfo: [AnyHashable: AnyHashable]) {
		guard let type = userInfo["type"] as? String else { return nil }
		
		switch type {
		case "title":
			self = .title
		case "tags":
			self = .tags
		case "rowTopic":
			guard let level = userInfo["level"] as? Int else { return nil }
			self = .rowTopic(level)
		case "rowNote":
			guard let level = userInfo["level"] as? Int else { return nil }
			self = .rowNote(level)
		case "backlinks":
			self = .backlinks
		default:
			return nil
		}
	}
	
}
