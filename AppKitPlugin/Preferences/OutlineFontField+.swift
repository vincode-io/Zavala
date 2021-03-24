//
//  OutlineFontField+.swift
//  Zavala
//
//  Created by Maurice Parker on 3/24/21.
//

import Foundation

extension OutlineFontField {
	
	var displayName: String {
		switch self {
		case .title:
			return L10n.title
		case .tags:
			return L10n.tags
		case .rowTopic(let level):
			return L10n.topicLevel(level)
		case .rowNote(let level):
			return L10n.noteLevel(level)
		case .backlinks:
			return L10n.backlinks
		}
	}
	
}
