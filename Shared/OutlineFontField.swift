//
//  OutlineFontField.swift
//  Zavala
//
//  Created by Maurice Parker on 3/23/21.
//

import Foundation

enum OutlineFontField: Hashable, CustomStringConvertible {
	case title
	case tags
	case rowTopic(Int) // Level
	case rowNote(Int) // Level
	case backlinks
	
	var description: String {
		switch self {
		case .title:
			return "title"
		case .tags:
			return "tags"
		case .rowTopic(let level):
			return  "rowTopic_\(level)"
		case .rowNote(let level):
			return "rowNote_\(level)"
		case .backlinks:
			return "backlinks"
		}
	}
	
	var displayOrder: Int {
		switch self {
		case .title:
			return 0
		case .tags:
			return 1
		case .rowTopic(let level):
			return level * 10
		case .rowNote(let level):
			return level * 15
		case .backlinks:
			return 10000
		}
	}

	init?(description: String) {
		switch description {
		case "title":
			self = .title
		case "tags":
			self = .tags
		case "backlinks":
			self = .backlinks
		default:
			let components = description.split(separator: "_")
			if components[0] == "rowTopic", let level = Int(components[1]) {
				self = .rowTopic(level)
			} else if components[0] == "rowNote", let level = Int(components[1]) {
				self = .rowNote(level)
			} else {
				return nil
			}
		}
	}
	
}
