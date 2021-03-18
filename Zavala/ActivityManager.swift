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
		
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.restoration.rawValue)
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

	func selectingDocument(_ documentContainer: DocumentContainer?, _ document: Document) {
		self.invalidateSelectDocument()
		self.selectDocumentActivity = self.makeSelectDocumentActivity(documentContainer, document)
		self.selectDocumentActivity!.becomeCurrent()
	}
	
	func invalidateSelectDocument() {
		selectDocumentActivity?.invalidate()
		selectDocumentActivity = nil
	}

}

extension ActivityManager {

	@objc func documentDidDelete(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [document.id.description])
	}
	
	private func makeSelectDocumentContainerActivity(_ documentContainer: DocumentContainer) -> NSUserActivity {
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.selectingDocumentContainer.rawValue)
		
		let title = L10n.seeDocumentsIn(documentContainer.name ?? "")
		activity.title = title
		
		activity.userInfo = [UserInfoKeys.documentContainerID: documentContainer.id.userInfo]
		activity.requiredUserInfoKeys = Set(activity.userInfo!.keys.map { $0 as! String })
	
		activity.isEligibleForSearch = true
		activity.isEligibleForPrediction = true

		let idString = documentContainer.id.description
		activity.persistentIdentifier = idString

		let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeCompositeContent as String)
		attributeSet.title = title
		attributeSet.relatedUniqueIdentifier = idString
		activity.contentAttributeSet = attributeSet
		
		return activity
	}
	
	private func makeSelectDocumentActivity(_ documentContainer: DocumentContainer?, _ document: Document) -> NSUserActivity {
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.selectingDocument.rawValue)

		let title = L10n.editDocument(document.title ?? "")
		activity.title = title
		
		if let documentContainer = documentContainer {
			activity.userInfo = [UserInfoKeys.documentContainerID: documentContainer.id.userInfo, UserInfoKeys.documentID: document.id.userInfo]
		} else {
			activity.userInfo = [UserInfoKeys.documentID: document.id.userInfo]
		}
		activity.requiredUserInfoKeys = Set(activity.userInfo!.keys.map { $0 as! String })
		
		if let keywords = document.tags?.map({ $0.name }) {
			activity.keywords = Set(keywords)
		}
		activity.isEligibleForSearch = true
		activity.isEligibleForPrediction = true
		
		if document.account?.type == .cloudKit {
			activity.isEligibleForHandoff = true
		}

		activity.persistentIdentifier = document.id.description
		
		return activity
	}
	
}
