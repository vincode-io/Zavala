//
//  OutlineFontCache.swift
//  Zavala
//
//  Created by Maurice Parker on 3/24/21.
//

import UIKit
import Combine

public extension Notification.Name {
	static let OutlineFontCacheDidRebuild = Notification.Name(rawValue: "OutlineFontCacheDidRebuild")
}

class OutlineFontCache {
	
	static let shared = OutlineFontCache()
	
	var lastOutlineFonts: OutlineFontDefaults?
	
	var title = UIFont.preferredFont(forTextStyle: .largeTitle)
	var tag = UIFont.preferredFont(forTextStyle: .body)
	var backline = UIFont.preferredFont(forTextStyle: .footnote)
	
	private var topics = [UIFont]()
	private var notes = [UIFont]()

	init() {
		buildCache(AppDefaults.shared.outlineFonts)
		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChangeNotification), name: UserDefaults.didChangeNotification, object: nil)
	}
	
	/// This is a 0 based index lookup
	func topic(level: Int) -> UIFont {
		if level < topics.count {
			return topics[level]
		} else {
			return topics.last ?? UIFont.preferredFont(forTextStyle: .body)
		}
	}
	
	/// This is a 0 based index lookup
	func note(level: Int) -> UIFont {
		if level < notes.count {
			return notes[level]
		} else {
			return notes.last ?? UIFont.preferredFont(forTextStyle: .body)
		}
	}
	
}

extension OutlineFontCache {

	@objc private func userDefaultsDidChangeNotification() {
		let fontDefaults = AppDefaults.shared.outlineFonts
		if fontDefaults != lastOutlineFonts {
			buildCache(fontDefaults)
		}
	}
	
	private func buildCache(_ fontDefaults: OutlineFontDefaults?) {
		lastOutlineFonts = fontDefaults
		guard let sortedFields = fontDefaults?.sortedFields else { return }
		
		topics.removeAll()
		notes.removeAll()
		
		for field in sortedFields {
			guard let config = fontDefaults?.rowFontConfigs[field],
				  let font = UIFont(name: config.name, size: CGFloat(config.size)) else { continue }
			
			switch field {
			case .title:
				title = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
			case .tags:
				tag = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
			case .rowTopic:
				topics.append(UIFontMetrics(forTextStyle: .body).scaledFont(for: font))
			case .rowNote:
				notes.append(UIFontMetrics(forTextStyle: .body).scaledFont(for: font))
			case .backlinks:
				backline = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: font).with(traits: .traitItalic)
			}
		}

		NotificationCenter.default.post(name: .OutlineFontCacheDidRebuild, object: self, userInfo: nil)
	}
	
}
