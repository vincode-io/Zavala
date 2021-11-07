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
	
	private var selectDocumentActivity: NSUserActivity?
    private var selectDocumentContainer: DocumentContainer?
    private var selectDocument: Document?

	var stateRestorationActivity: NSUserActivity {
		if let activity = selectDocumentActivity {
			return activity
		}
		
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.restoration)
		activity.persistentIdentifier = UUID().uuidString
		activity.becomeCurrent()
		return activity
	}
	
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(documentDidDelete(_:)), name: .DocumentDidDelete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(documentTitleDidChange(_:)), name: .DocumentTitleDidChange, object: nil)
	}

	func selectingDocument(_ documentContainer: DocumentContainer?, _ document: Document) {
		self.invalidateSelectDocument()
		self.selectDocumentActivity = self.makeSelectDocumentActivity(documentContainer, document)
		self.selectDocumentActivity!.becomeCurrent()
        self.selectDocumentContainer = documentContainer
        self.selectDocument = document
	}
	
	func invalidateSelectDocument() {
		selectDocumentActivity?.invalidate()
		selectDocumentActivity = nil
        selectDocumentContainer = nil
        selectDocument = nil
	}

}

extension ActivityManager {

	@objc func documentDidDelete(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [document.id.description])
	}
	
    @objc func documentTitleDidChange(_ note: Notification) {
        guard let document = note.object as? Document, document == selectDocument else { return }
        selectingDocument(selectDocumentContainer, document)
    }
    
	private func makeSelectDocumentContainerActivity(_ documentContainer: DocumentContainer) -> NSUserActivity {
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.selectingDocumentContainer)
		
		let title = L10n.seeDocumentsIn(documentContainer.name ?? "")
		activity.title = title
		
		activity.userInfo = [UserInfoKeys.pin: Pin(container: documentContainer).userInfo]
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
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.selectingDocument)

		let title = L10n.editDocument(document.title ?? "")
		activity.title = title
		
		activity.userInfo = [UserInfoKeys.pin: Pin(container: documentContainer, document: document).userInfo]
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
