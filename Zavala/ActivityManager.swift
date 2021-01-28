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
	case selectDocumentContainer = "SelectDocumentContainer"
	case selectDocument = "SelectDocument"
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
		NotificationCenter.default.addObserver(self, selector: #selector(documentDidDelete(_:)), name: .DocumentDidDelete, object: nil)
	}

	func selectingDocumentContainer(_ documentContainer: DocumentContainer) {
		self.invalidateSelectDocumentContainer()
		self.selectDocumentContainerActivity = self.makeSelectDocumentContainerActivity(documentContainer)
		self.selectDocumentContainerActivity!.becomeCurrent()
	}
	
	func invalidateSelectDocumentContainer() {
		invalidateSelectDocument()
		selectDocumentContainerActivity?.invalidate()
		selectDocumentContainerActivity = nil
	}

	func selectingDocument(_ documentContainer: DocumentContainer, _ document: Document) {
		self.invalidateSelectDocument()
		self.selectDocumentActivity = self.makeSelectDocumentActivity(documentContainer, document)
		self.selectDocumentActivity!.becomeCurrent()
		self.updateIndex(forDocument: document)
	}
	
	func invalidateSelectDocument() {
		selectDocumentActivity?.invalidate()
		selectDocumentActivity = nil
	}

	func updateIndex(forDocument document: Document) {
		DispatchQueue.main.async {
			let attributeSet = self.makeSearchableItemAttributes(forDocument: document)
			let identifier = attributeSet.relatedUniqueIdentifier
			let searchableItem = CSSearchableItem(uniqueIdentifier: identifier, domainIdentifier: "io.vincode", attributeSet: attributeSet)
			CSSearchableIndex.default().indexSearchableItems([searchableItem])
		}
	}
	
}

extension ActivityManager {

	@objc func documentDidDelete(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [document.id.description])
	}
	
	private func makeSelectDocumentContainerActivity(_ documentContainer: DocumentContainer) -> NSUserActivity {
		let activity = NSUserActivity(activityType: ActivityType.selectDocumentContainer.rawValue)
		
		let title = L10n.seeDocumentsIn(documentContainer.name ?? "")
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
	
	private func makeSelectDocumentActivity(_ documentContainer: DocumentContainer, _ document: Document) -> NSUserActivity {
		let activity = NSUserActivity(activityType: ActivityType.selectDocument.rawValue)

		let title = L10n.editDocument(document.title ?? "")
		activity.title = title
		
		activity.userInfo = [UserInfoKeys.documentContainerID: documentContainer.id.userInfo, UserInfoKeys.documentID: document.id.userInfo]
		activity.requiredUserInfoKeys = Set(activity.userInfo!.keys.map { $0 as! String })
		
		let keywords = makeKeywords(document.title ?? "")
		activity.keywords = Set(keywords)
		activity.isEligibleForSearch = true
		activity.isEligibleForPrediction = true
		
		if document.account?.type == .cloudKit {
			activity.isEligibleForHandoff = true
		}

		activity.persistentIdentifier = document.id.description
		
		return activity
	}
	
	private func makeSearchableItemAttributes(forDocument document: Document) -> CSSearchableItemAttributeSet {
		let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
		attributeSet.title = document.title ?? ""
		attributeSet.keywords = makeKeywords(document.title ?? "")
		attributeSet.relatedUniqueIdentifier = document.id.description
		attributeSet.textContent = document.content
		attributeSet.contentModificationDate = document.updated
		return attributeSet
	}
	
	private func makeKeywords(_ value: String?) -> [String] {
		return value?.components(separatedBy: " ").filter { $0.count > 2 } ?? []
	}
	
}
