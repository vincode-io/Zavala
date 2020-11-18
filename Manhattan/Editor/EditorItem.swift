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
	var parentID: String?
	var attributedText: NSAttributedString?
	var children: [EditorItem]
	
	init(headline: Headline, parentID: String?, children: [EditorItem]) {
		self.id = headline.id
		self.attributedText = headline.attributedText
		self.parentID = parentID
		self.children = children
	}
	
	static func editorItem(_ headline: Headline, parentID: String?) -> EditorItem {
		let children = headline.headlines?.map { editorItem($0, parentID: headline.id) } ?? [EditorItem]()
		return EditorItem(headline: headline, parentID: parentID, children: children)
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

