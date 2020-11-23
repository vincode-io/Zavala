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
	case selectOutlineProvider = "SelectOutlineProvider"
	case selectOutline = "SelectOutline"
}

class ActivityManager {
	
	private var selectOutlineProviderActivity: NSUserActivity?
	private var selectOutlineActivity: NSUserActivity?

	var stateRestorationActivity: NSUserActivity {
		if let activity = selectOutlineActivity {
			return activity
		}
		
		if let activity = selectOutlineProviderActivity {
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

	func selectingOutlineProvider(_ outlineProvider: OutlineProvider) {
		invalidateSelectOutlineProvider()
		selectOutlineProviderActivity = makeSelectOutlineProviderActivity(outlineProvider)
		donate(selectOutlineProviderActivity!)
	}
	
	func invalidateSelectOutlineProvider() {
		invalidateSelectOutline()
		selectOutlineProviderActivity?.invalidate()
		selectOutlineProviderActivity = nil
	}

	func selectingOutline(_ outlineProvider: OutlineProvider, _ outline: Outline) {
		invalidateSelectOutline()
		selectOutlineActivity = makeSelectOutlineActivity(outlineProvider, outline)
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
	
	private func makeSelectOutlineProviderActivity(_ outlineProvider: OutlineProvider) -> NSUserActivity {
		let activity = NSUserActivity(activityType: ActivityType.selectOutlineProvider.rawValue)
		
		let localizedText = NSLocalizedString("See outlines in  “%@”", comment: "See outlines in Folder")
		let title = NSString.localizedStringWithFormat(localizedText as NSString, outlineProvider.name ?? "") as String
		activity.title = title
		
		let keywords = makeKeywords(title)
		activity.keywords = Set(keywords)
		activity.isEligibleForSearch = true
		
		activity.userInfo = [UserInfoKeys.outlineProviderID: outlineProvider.id.userInfo]
		activity.requiredUserInfoKeys = Set(activity.userInfo!.keys.map { $0 as! String })

		activity.isEligibleForPrediction = true
		
		let idString = outlineProvider.id.description
		activity.persistentIdentifier = idString

		let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeCompositeContent as String)
		attributeSet.title = title
		attributeSet.keywords = keywords
		attributeSet.relatedUniqueIdentifier = idString
		activity.contentAttributeSet = attributeSet
		
		return activity
	}
	
	private func makeSelectOutlineActivity(_ outlineProvider: OutlineProvider, _ outline: Outline) -> NSUserActivity {
		let activity = NSUserActivity(activityType: ActivityType.selectOutline.rawValue)

		let localizedText = NSLocalizedString("Edit outline “%@”", comment: "Edit outline")
		let title = NSString.localizedStringWithFormat(localizedText as NSString, outline.title ?? "") as String
		activity.title = title
		
		let keywords = makeKeywords(title)
		activity.keywords = Set(keywords)
		activity.isEligibleForSearch = true
		
		activity.userInfo = [UserInfoKeys.outlineProviderID: outlineProvider.id.userInfo, UserInfoKeys.outlineID: outline.id.userInfo]
		activity.requiredUserInfoKeys = Set(activity.userInfo!.keys.map { $0 as! String })

		activity.isEligibleForPrediction = true
		
		let idString = outline.id.description
		activity.persistentIdentifier = idString
		
		let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeCompositeContent as String)
		attributeSet.title = title
		attributeSet.keywords = keywords
		attributeSet.relatedUniqueIdentifier = idString
		activity.contentAttributeSet = attributeSet
		
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
			let searchableItem = CSSearchableItem(uniqueIdentifier: identifier, domainIdentifier: nil, attributeSet: attributeSet)
			CSSearchableIndex.default().indexSearchableItems([searchableItem])
		}
		
		activity.becomeCurrent()
	}
	
}
