//
//  OutlineFontField.swift
//  Zavala
//
//  Created by Maurice Parker on 3/23/21.
//

import Foundation

enum OutineFontField {
	case title
	case tags
	case rowTopic(Int) // Level
	case rowNote(Int) // Level
	case backlinks
	
	public var userInfo: [AnyHashable: AnyHashable] {
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

}
