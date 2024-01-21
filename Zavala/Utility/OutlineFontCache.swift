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

class OutlineFontCache {
	
	static let shared = OutlineFontCache()
	
	var lastOutlineFonts: OutlineFontDefaults?
	
	var titleFont = UIFont.preferredFont(forTextStyle: .largeTitle)
	var titleColor = UIColor.label
	var tagFont = UIFont.preferredFont(forTextStyle: .body)
	var tagColor = UIColor.label
	var backlinkFont = UIFont.preferredFont(forTextStyle: .footnote).with(traits: .traitItalic)
	var backlinkColor = UIColor.secondaryLabel

	private var topicFonts = [UIFont]()
	private var topicColors = [UIColor]()
	private var metadatumFonts = [UIFont]()
	private var noteFonts = [UIFont]()
	private var noteColors = [UIColor]()

	init() {
		buildCache(AppDefaults.shared.outlineFonts)
		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
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
	func metadataFont(level: Int) -> UIFont {
		if level < metadatumFonts.count {
			return metadatumFonts[level]
		} else {
			return metadatumFonts.last ?? UIFont.preferredFont(forTextStyle: .title1)
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

	@objc private func userDefaultsDidChange() {
		let outlineFonts = AppDefaults.shared.outlineFonts
		if outlineFonts != lastOutlineFonts {
			buildCache(outlineFonts)
		}
	}
	
	@objc private func contentSizeCategoryDidChange() {
		buildCache(AppDefaults.shared.outlineFonts)
	}
	
	private func buildCache(_ outlineFonts: OutlineFontDefaults?) {
		lastOutlineFonts = outlineFonts
		guard let sortedFields = outlineFonts?.sortedFields else { return }
		
		topicFonts.removeAll()
		topicColors.removeAll()
		noteFonts.removeAll()
		noteColors.removeAll()
		
		for field in sortedFields {
			guard let config = outlineFonts?.rowFontConfigs[field],
				  let font = UIFont(name: config.name, size: CGFloat(config.size)) else { continue }
			
			switch field {
			case .title:
				titleFont = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font).with(traits: .traitBold)
				titleColor = config.secondaryColor ? .secondaryLabel : .label
			case .tags:
				tagFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: font).with(traits: .traitBold)
				tagColor = config.secondaryColor ? .secondaryLabel : .label
			case .rowTopic:
				let topicFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
				topicFonts.append(topicFont)
				topicColors.append(config.secondaryColor ? .secondaryLabel : .label)
				let metadataFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: font.withSize(font.pointSize - 2))
				metadatumFonts.append(metadataFont)
			case .rowNote:
				noteFonts.append(UIFontMetrics(forTextStyle: .body).scaledFont(for: font))
				noteColors.append(config.secondaryColor ? .secondaryLabel : .label)
			case .backlinks:
				backlinkFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: font).with(traits: .traitItalic)
				backlinkColor = config.secondaryColor ? .secondaryLabel : .label
			}
		}

		NotificationCenter.default.post(name: .OutlineFontCacheDidRebuild, object: self, userInfo: nil)
	}
	
}
