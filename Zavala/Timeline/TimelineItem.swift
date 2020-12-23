//
//  TimelineItem.swift
//  Zavala
//
//  Created by Maurice Parker on 11/14/20.
//

import UIKit
import Templeton

final class TimelineItem: NSObject, NSCopying, Identifiable {
	
	let id: EntityID

	init(id: EntityID) {
		self.id = id
	}

	static func timelineItem(_ outline: Outline) -> TimelineItem {
		return TimelineItem(id: outline.id)
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? TimelineItem else { return false }
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
