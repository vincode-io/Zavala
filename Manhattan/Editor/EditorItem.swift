//
//  EditorItem.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/15/20.
//

import UIKit
import Templeton

final class EditorItem:  NSObject, NSCopying, Identifiable {
	var id: String
	var attributedText: NSAttributedString?
	var isExpanded: Bool
	var children: [EditorItem]
	
	init(headline: Headline, children: [EditorItem]) {
		self.id = headline.id
		self.attributedText = headline.attributedText
		self.isExpanded = headline.isExpanded ?? true
		self.children = children
	}
	
	static func editorItem(_ headline: Headline) -> EditorItem {
		let children = headline.headlines?.map { editorItem($0) } ?? [EditorItem]()
		return EditorItem(headline: headline, children: children)
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? EditorItem else { return false }
		if self === other { return true }
		return id == other.id
	}
	
	override var hash: Int {
		var hasher = Hasher()
		hasher.combine(id)
		return hasher.finalize()
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		return self
	}

}

