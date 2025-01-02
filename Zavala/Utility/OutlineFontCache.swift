//
//  OutlineFontCache.swift
//  Zavala
//
//  Created by Maurice Parker on 3/24/21.
//

import UIKit
import VinOutlineKit
import Combine

public extension Notification.Name {
	static let OutlineFontCacheDidRebuild = Notification.Name(rawValue: "OutlineFontCacheDidRebuild")
}

@MainActor
class OutlineFontCache {
	
	static let shared = OutlineFontCache()
	
	var outlineFonts: OutlineFontDefaults?
	var textZoom = 0
	
	var titleFont = UIFont.preferredFont(forTextStyle: .largeTitle)
	var titleColor = UIColor.label
	var tagFont = UIFont.preferredFont(forTextStyle: .body)
	var tagColor = UIColor.label
	var backlinkFont = UIFont.preferredFont(forTextStyle: .footnote).with(traits: .traitItalic)
	var backlinkColor = UIColor.secondaryLabel

	private var numberingFonts = [UIFont]()
	private var numberingColors = [UIColor]()
	private var topicFonts = [UIFont]()
	private var topicColors = [UIColor]()
	private var noteFonts = [UIFont]()
	private var noteColors = [UIColor]()

	init() {
		buildCache()
		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
	}
	
	/// This is a 0 based index lookup
	func numberingFont(level: Int) -> UIFont {
		if level < numberingFonts.count {
			return numberingFonts[level]
		} else {
			return numberingFonts.last ?? UIFont.preferredFont(forTextStyle: .body)
		}
	}
	
	/// This is a 0 based index lookup
	func numberingColor(level: Int) -> UIColor {
		if level < numberingColors.count {
			return numberingColors[level]
		} else {
			return numberingColors.last ?? .label
		}
	}

	/// This is a 0 based index lookup
	func topicFont(level: Int) -> UIFont {
		if level < topicFonts.count {
			return topicFonts[level]
		} else {
			return topicFonts.last ?? UIFont.preferredFont(forTextStyle: .body)
		}
	}
	
	/// This is a 0 based index lookup
	func topicColor(level: Int) -> UIColor {
		if level < topicColors.count {
			return topicColors[level]
		} else {
			return topicColors.last ?? .label
		}
	}

	/// This is a 0 based index lookup
	func noteFont(level: Int) -> UIFont {
		if level < noteFonts.count {
			return noteFonts[level]
		} else {
			return noteFonts.last ?? UIFont.preferredFont(forTextStyle: .body)
		}
	}
	
	/// This is a 0 based index lookup
	func noteColor(level: Int) -> UIColor {
		if level < noteColors.count {
			return noteColors[level]
		} else {
			return noteColors.last ?? .secondaryLabel
		}
	}

}

extension OutlineFontCache {

	@objc nonisolated private func userDefaultsDidChange() {
		Task { @MainActor in
			let defaults = AppDefaults.shared
			if outlineFonts != defaults.outlineFonts || textZoom != defaults.textZoom {
				buildCache()
			}
		}
	}
	
	@objc private func contentSizeCategoryDidChange() {
		buildCache()
	}
	
	private func buildCache() {
		outlineFonts = AppDefaults.shared.outlineFonts
		textZoom = AppDefaults.shared.textZoom
		
		guard let sortedFields = outlineFonts?.sortedFields else { return }
		
		numberingFonts.removeAll()
		numberingColors.removeAll()
		topicFonts.removeAll()
		topicColors.removeAll()
		noteFonts.removeAll()
		noteColors.removeAll()
		
		for field in sortedFields {
			guard let config = outlineFonts?.rowFontConfigs[field] else { continue }
			
			let fontSize = config.size + textZoom > 0 ? config.size + textZoom : 1
			guard let font = UIFont(name: config.name, size: CGFloat(fontSize)) else { continue }
			
			switch field {
			case .title:
				titleFont = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font).with(traits: .traitBold)
				titleColor = config.color.uiColor
			case .tags:
				tagFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: font).with(traits: .traitBold)
				tagColor = config.color.uiColor
			case .rowNumbering:
				let numberingFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
				numberingFonts.append(numberingFont)
				numberingColors.append(config.color.uiColor)
			case .rowTopic:
				let topicFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
				topicFonts.append(topicFont)
				topicColors.append(config.color.uiColor)
			case .rowNote:
				noteFonts.append(UIFontMetrics(forTextStyle: .body).scaledFont(for: font))
				noteColors.append(config.color.uiColor)
			case .backlinks:
				backlinkFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: font).with(traits: .traitItalic)
				backlinkColor = config.color.uiColor
			}
		}

		NotificationCenter.default.post(name: .OutlineFontCacheDidRebuild, object: self, userInfo: nil)
	}
	
}
