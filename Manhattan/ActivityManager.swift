//
//  ActivityManager.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/13/20.
//

import UIKit
import CoreSpotlight
import CoreServices
import Templeton

enum ActivityType: String {
	case restoration = "Restoration"
	case selectFolder = "SelectFolder"
	case selectOutline = "SelectOutline"
}

struct ActivityUserInfoKeys {
	static let folderID = "folderID"
	static let outlineID = "outlineID"
}

class ActivityManager {
	
	private var selectFolderActivity: NSUserActivity?
	private var selectOutlineActivity: NSUserActivity?

	var stateRestorationActivity: NSUserActivity {
		if let activity = selectOutlineActivity {
			return activity
		}
		
		if let activity = selectFolderActivity {
			return activity
		}
		
		let activity = NSUserActivity(activityType: ActivityType.restoration.rawValue)
		activity.persistentIdentifier = UUID().uuidString
		activity.becomeCurrent()
		return activity
	}
	
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(folderDidDelete(_:)), name: .FolderDidDelete, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineDidDelete(_:)), name: .OutlineDidDelete, object: nil)
	}

	func selectingFolder(_ folder: Folder) {
		invalidateSelectFolder()
		selectFolderActivity = makeSelectFolderActivity(folder)
		donate(selectFolderActivity!)
	}
	
	func invalidateSelectFolder() {
		invalidateSelectOutline()
		selectFolderActivity?.invalidate()
		selectFolderActivity = nil
	}

	func selectingOutline(folder: Folder, outline: Outline) {
		invalidateSelectOutline()
		selectOutlineActivity = makeSelectOutlineActivity(folder, outline)
		donate(selectOutlineActivity!)
	}
	
	func invalidateSelectOutline() {
		selectOutlineActivity?.invalidate()
		selectOutlineActivity = nil
	}

}

extension ActivityManager {

	@objc func folderDidDelete(_ note: Notification) {
		guard let folder = note.object as? Folder else { return }

		var ids = [String]()
		ids.append(folder.id.description)
		
		for outline in folder.outlines ?? [Outline]() {
			ids.append(outline.id.description)
		}
		
		CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ids)
	}
	
	@objc func outlineDidDelete(_ note: Notification) {
		guard let outline = note.object as? Outline else { return }
		CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [outline.id.description])
	}
	
	private func makeSelectFolderActivity(_ folder: Folder) -> NSUserActivity {
		let activity = NSUserActivity(activityType: ActivityType.selectFolder.rawValue)
		
		let localizedText = NSLocalizedString("See outlines in  “%@”", comment: "See outlines in Folder")
		let title = NSString.localizedStringWithFormat(localizedText as NSString, folder.name ?? "") as String
		activity.title = title
		
		activity.keywords = Set(makeKeywords(title))
		activity.isEligibleForSearch = true
		
		activity.userInfo = [ActivityUserInfoKeys.folderID: folder.id.userInfo]
		activity.requiredUserInfoKeys = Set(activity.userInfo!.keys.map { $0 as! String })

		activity.isEligibleForPrediction = true
		
		let idString = folder.id.description
		activity.persistentIdentifier = idString
		activity.contentAttributeSet?.relatedUniqueIdentifier = idString
		
		return activity
	}
	
	private func makeSelectOutlineActivity(_ folder: Folder, _ outline: Outline) -> NSUserActivity {
		let activity = NSUserActivity(activityType: ActivityType.selectOutline.rawValue)

		let localizedText = NSLocalizedString("Edit outline “%@”", comment: "Edit outline")
		let title = NSString.localizedStringWithFormat(localizedText as NSString, outline.name ?? "") as String
		activity.title = title
		
		activity.keywords = Set(makeKeywords(title))
		activity.isEligibleForSearch = true
		
		activity.userInfo = [ActivityUserInfoKeys.outlineID: outline.id.userInfo]
		activity.requiredUserInfoKeys = Set(activity.userInfo!.keys.map { $0 as! String })

		activity.isEligibleForPrediction = true
		
		let idString = outline.id.description
		activity.persistentIdentifier = idString
		activity.contentAttributeSet?.relatedUniqueIdentifier = idString
		
		return activity
	}
	
	private func makeKeywords(_ value: String?) -> [String] {
		return value?.components(separatedBy: " ").filter { $0.count > 2 } ?? []
	}
	
	private func donate(_ activity: NSUserActivity) {
		// You have to put the search item in the index or the activity won't index
		// itself because the relatedUniqueIdentifier on the activity attributeset is populated.
		if let attributeSet = activity.contentAttributeSet {
			let identifier = attributeSet.relatedUniqueIdentifier
			let tempAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
			let searchableItem = CSSearchableItem(uniqueIdentifier: identifier, domainIdentifier: nil, attributeSet: tempAttributeSet)
			CSSearchableIndex.default().indexSearchableItems([searchableItem])
		}
		
		activity.becomeCurrent()
	}
	
}
