//
//  OutlineFontField.swift
//  Zavala
//
//  Created by Maurice Parker on 3/23/21.
//

import Foundation

enum OutlineFontField: Hashable, Equatable, CustomStringConvertible {
	case title
	case tags
	case rowNumbering(Int) // Level
	case rowTopic(Int) // Level
	case rowNote(Int) // Level
	case backlinks
	
	var isSecondary: Bool {
		switch self {
		case .tags, .rowNote, .backlinks:
			return true
		default:
			return false
		}
	}
	
	var description: String {
		switch self {
		case .title:
			return "title"
		case .tags:
			return "tags"
		case .rowNumbering(let level):
			return  "rowNumbering_\(level)"
		case .rowTopic(let level):
			return  "rowTopic_\(level)"
		case .rowNote(let level):
			return "rowNote_\(level)"
		case .backlinks:
			return "backlinks"
		}
	}
	
	var displayName: String {
		switch self {
		case .title:
			return .titleLabel
		case .tags:
			return .tagsLabel
		case .rowNumbering(let level):
			return .numberingLevelLabel(level: level)
		case .rowTopic(let level):
			return .topicLevelLabel(level: level)
		case .rowNote(let level):
			return .noteLevelLabel(level: level)
		case .backlinks:
			return .backlinksLabel
		}
	}

	var displayOrder: Int {
		switch self {
		case .title:
			return 0
		case .tags:
			return 1
		case .rowNumbering(let level):
			return (level * 10) - 5
		case .rowTopic(let level):
			return level * 10
		case .rowNote(let level):
			return (level * 10) + 5
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
			if components[0] == "rowNumbering", let level = Int(components[1]) {
				self = .rowNumbering(level)
			} else if components[0] == "rowTopic", let level = Int(components[1]) {
				self = .rowTopic(level)
			} else if components[0] == "rowNote", let level = Int(components[1]) {
				self = .rowNote(level)
			} else {
				return nil
			}
		}
	}
	
}
