//
//  TimelineItem.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/14/20.
//

import UIKit
import Templeton

final class TimelineItem:  NSObject, NSCopying, Identifiable {
	let id: EntityID
	let title: String?
	let updateDate: String?

	init(id: EntityID, title: String?, updateDate: String?) {
		self.id = id
		self.title = title
		self.updateDate = updateDate
	}
	
	private static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter
	}()

	private static let timeFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .none
		formatter.timeStyle = .short
		return formatter
	}()
	
	private static func dateString(_ date: Date?) -> String {
		guard let date = date else {
			return NSLocalizedString("Not Available", comment: "Not Available")
		}
		
		if Calendar.dateIsToday(date) {
			return timeFormatter.string(from: date)
		}
		return dateFormatter.string(from: date)
	}

	static func timelineItem(_ outline: Outline) -> TimelineItem {
		let updateDate = Self.dateString(outline.updated)
		return TimelineItem(id: outline.id, title: outline.name, updateDate: updateDate)
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? TimelineItem else { return false }
		if self === other { return true }
		return id == other.id && title == other.title && updateDate == other.updateDate
	}
	
	override var hash: Int {
		var hasher = Hasher()
		hasher.combine(id)
		hasher.combine(title)
		hasher.combine(updateDate)
		return hasher.finalize()
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		return self
	}

}
