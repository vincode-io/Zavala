//
//  ActivityManager.swift
//  Zavala
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
	
	private var selectDocumentContainerActivity: NSUserActivity?
	private var selectDocumentActivity: NSUserActivity?

	var stateRestorationActivity: NSUserActivity {
		if let activity = selectDocumentActivity {
			return activity
		}
		
		if let activity = selectDocumentContainerActivity {
			return activity
		}
		
		let activity = NSUserActivity(activityType: ActivityType.restoration.rawValue)
		activity.persistentIdentifier = UUID().uuidString
		activity.becomeCurrent()
		return activity
	}
	
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(folderDidDelete(_:)), name: .FolderDidDelete, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineDidDelete(_:)), name: .DocumentDidDelete, object: nil)
	}

	func selectingDocumentContainer(_ documentContainer: DocumentContainer) {
		invalidateSelectDocumentContainer()
		selectDocumentContainerActivity = makeSelectDocumentContainerActivity(documentContainer)
		donate(selectDocumentContainerActivity!)
	}
	
	func invalidateSelectDocumentContainer() {
		invalidateSelectDocument()
		selectDocumentContainerActivity?.invalidate()
		selectDocumentContainerActivity = nil
	}

	func selectingDocument(_ documentContainer: DocumentContainer, _ document: Document) {
		invalidateSelectDocument()
		selectDocumentActivity = makeSelectDocumentActivity(documentContainer, document)
		donate(selectDocumentActivity!)
	}
	
	func invalidateSelectDocument() {
		selectDocumentActivity?.invalidate()
		selectDocumentActivity = nil
	}

}

extension ActivityManager {

	@objc func folderDidDelete(_ note: Notification) {
		guard let folder = note.object as? Folder else { return }

		var ids = [String]()
		ids.append(folder.id.description)
		
		for outline in folder.outlines ?? [Document]() {
			ids.append(outline.id.description)
		}
		
		CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ids)
	}
	
	@objc func outlineDidDelete(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [document.id.description])
	}
	
	private func makeSelectDocumentContainerActivity(_ documentContainer: DocumentContainer) -> NSUserActivity {
		let activity = NSUserActivity(activityType: ActivityType.selectOutlineProvider.rawValue)
		
		let title = L10n.seeOutlinesIn(documentContainer.name ?? "")
		activity.title = title
		
		activity.userInfo = [UserInfoKeys.documentContainerID: documentContainer.id.userInfo]
		activity.requiredUserInfoKeys = Set(activity.userInfo!.keys.map { $0 as! String })
	
		let keywords = makeKeywords(title)
		activity.keywords = Set(keywords)
		activity.isEligibleForSearch = true
		activity.isEligibleForPrediction = true

		let idString = documentContainer.id.description
		activity.persistentIdentifier = idString

		let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeCompositeContent as String)
		attributeSet.title = title
		attributeSet.keywords = keywords
		attributeSet.relatedUniqueIdentifier = idString
		activity.contentAttributeSet = attributeSet
		
		return activity
	}
	
	private func makeSelectDocumentActivity(_ outlineProvider: DocumentContainer, _ document: Document) -> NSUserActivity {
		let activity = NSUserActivity(activityType: ActivityType.selectOutline.rawValue)

		let title = L10n.editOutline(document.title ?? "")
		activity.title = title
		
		activity.userInfo = [UserInfoKeys.documentContainerID: outlineProvider.id.userInfo, UserInfoKeys.documentID: document.id.userInfo]
		activity.requiredUserInfoKeys = Set(activity.userInfo!.keys.map { $0 as! String })
		
		let keywords = makeKeywords(title)
		activity.keywords = Set(keywords)
		activity.isEligibleForSearch = true
		activity.isEligibleForPrediction = true
		
		if document.account?.type == .cloudKit {
			activity.isEligibleForHandoff = true
		}

		let idString = document.id.description
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
			let tempAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
			let searchableItem = CSSearchableItem(uniqueIdentifier: identifier, domainIdentifier: nil, attributeSet: tempAttributeSet)
			CSSearchableIndex.default().indexSearchableItems([searchableItem])
		}
		
		activity.becomeCurrent()
	}
	
}
