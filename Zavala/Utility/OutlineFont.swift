//
//  OutlineFont.swift
//  
//
//  Created by Maurice Parker on 12/17/20.
//

import UIKit

public struct OutlineFont {
	
	public static var topicCapHeight: CGFloat {
		return topic.capHeight
	}
	
	public static var topic: UIFont {
		#if targetEnvironment(macCatalyst)
		let font = UIFont.preferredFont(forTextStyle: .body)
		return font.withSize(font.pointSize + 1)
		#else
		return UIFont.preferredFont(forTextStyle: .body)
		#endif
	}
	
	public static var note: UIFont {
		#if targetEnvironment(macCatalyst)
		return UIFont.preferredFont(forTextStyle: .body)
		#else
		let font = UIFont.preferredFont(forTextStyle: .body)
		return font.withSize(font.pointSize - 1)
		#endif
	}
	
	public static var backlink: UIFont {
		#if targetEnvironment(macCatalyst)
		let font = UIFont.preferredFont(forTextStyle: .footnote)
		return font.withSize(font.pointSize + 2).with(traits: .traitItalic)
		#else
		let font = UIFont.preferredFont(forTextStyle: .footnote)
		return font.withSize(font.pointSize + 1).with(traits: .traitItalic)
		#endif
	}
	
}
