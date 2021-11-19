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
	var backline = UIFont.preferredFont(forTextStyle: .footnote).with(traits: .traitItalic)
	
	private var topics = [UIFont]()
	private var metadatum = [UIFont]()
	private var notes = [UIFont]()

	init() {
		buildCache(AppDefaults.shared.outlineFonts)
		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChangeNotification), name: UserDefaults.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChangeNotification), name: UIContentSizeCategory.didChangeNotification, object: nil)
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
	func metadata(level: Int) -> UIFont {
		if level < metadatum.count {
			return metadatum[level]
		} else {
			return metadatum.last ?? UIFont.preferredFont(forTextStyle: .title1)
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
		let outlineFonts = AppDefaults.shared.outlineFonts
		if outlineFonts != lastOutlineFonts {
			buildCache(outlineFonts)
		}
	}
	
	@objc private func contentSizeCategoryDidChangeNotification() {
		buildCache(AppDefaults.shared.outlineFonts)
	}
	
	private func buildCache(_ outlineFonts: OutlineFontDefaults?) {
		lastOutlineFonts = outlineFonts
		guard let sortedFields = outlineFonts?.sortedFields else { return }
		
		topics.removeAll()
		notes.removeAll()
		
		for field in sortedFields {
			guard let config = outlineFonts?.rowFontConfigs[field],
				  let font = UIFont(name: config.name, size: CGFloat(config.size)) else { continue }
			
			switch field {
			case .title:
				title = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font).with(traits: .traitBold)
			case .tags:
				tag = UIFontMetrics(forTextStyle: .body).scaledFont(for: font).with(traits: .traitBold)
			case .rowTopic:
				let topicFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
				topics.append(topicFont)
				let metadataFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: font.withSize(font.pointSize - 2))
				metadatum.append(metadataFont)
			case .rowNote:
				notes.append(UIFontMetrics(forTextStyle: .body).scaledFont(for: font))
			case .backlinks:
				backline = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: font).with(traits: .traitItalic)
			}
		}

		NotificationCenter.default.post(name: .OutlineFontCacheDidRebuild, object: self, userInfo: nil)
	}
	
}
