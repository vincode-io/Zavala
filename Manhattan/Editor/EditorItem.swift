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
	var text: Data?
	weak var parentHeadline: Headline?
	var children: [EditorItem]

	var plainText: String? {
		get {
			guard let text = text else { return nil }
			return String(data: text, encoding: .utf8)
		}
		set {
			text = newValue?.data(using: .utf8)
		}
	}
	
	init(headline: Headline, parentHeadline: Headline?, children: [EditorItem]) {
		self.id = headline.id
		self.text = headline.text
		self.parentHeadline = parentHeadline
		self.children = children
	}
	
	static func editorItem(_ headline: Headline, parentHeadline: Headline?) -> EditorItem {
		let children = headline.headlines?.map { editorItem($0, parentHeadline: headline) } ?? [EditorItem]()
		return EditorItem(headline: headline, parentHeadline: parentHeadline, children: children)
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

