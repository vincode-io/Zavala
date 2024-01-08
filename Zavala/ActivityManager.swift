//
//  ActivityManager.swift
//  Zavala
//
//  Created by Maurice Parker on 11/13/20.
//

import UIKit
import CoreSpotlight
import CoreServices
import VinOutlineKit

class ActivityManager {
	
	private var selectDocumentContainerActivity: NSUserActivity?
	private var selectDocumentActivity: NSUserActivity?
    private var selectDocumentContainers: [DocumentContainer]?
    private var selectDocument: Document?

	var stateRestorationActivity: NSUserActivity {
		if let activity = selectDocumentActivity {
			return activity
		}
		
		if let activity = selectDocumentContainerActivity {
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
    
    func selectingDocumentContainers(_ documentContainers: [DocumentContainer]) {
        self.invalidateSelectDocumentContainers()
        self.selectDocumentContainerActivity = self.makeSelectDocumentContainerActivity(documentContainers)
        self.selectDocumentContainerActivity!.becomeCurrent()
    }
    
    func invalidateSelectDocumentContainers() {
        invalidateSelectDocument()
        selectDocumentContainerActivity?.invalidate()
        selectDocumentContainerActivity = nil
    }

	func selectingDocument(_ documentContainers: [DocumentContainer]?, _ document: Document) {
		self.invalidateSelectDocument()
		self.selectDocumentActivity = self.makeSelectDocumentActivity(documentContainers, document)
		self.selectDocumentActivity!.becomeCurrent()
        self.selectDocumentContainers = documentContainers
        self.selectDocument = document
	}
	
	func invalidateSelectDocument() {
		selectDocumentActivity?.invalidate()
		selectDocumentActivity = nil
        selectDocumentContainers = nil
        selectDocument = nil
	}

}

// MARK: Helpers

private extension ActivityManager {

	@objc func documentDidDelete(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [document.id.description])
	}
	
	func makeSelectDocumentContainerActivity(_ documentContainers: [DocumentContainer]) -> NSUserActivity {
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.selectingDocumentContainer)
		
		let title = String.seeDocumentsInPrompt(documentContainerTitle: documentContainers.title)
		activity.title = title
		
		activity.userInfo = [Pin.UserInfoKeys.pin: Pin(containers: documentContainers).userInfo]
		activity.requiredUserInfoKeys = Set(activity.userInfo!.keys.map { $0 as! String })
		
		return activity
	}
	
    @objc func documentTitleDidChange(_ note: Notification) {
        guard let document = note.object as? Document, document == selectDocument else { return }
        selectingDocument(selectDocumentContainers, document)
    }
    
	func makeSelectDocumentActivity(_ documentContainers: [DocumentContainer]?, _ document: Document) -> NSUserActivity {
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.selectingDocument)

		let title = String.editDocumentPrompt(documentTitle: document.title ?? "")
		activity.title = title
		
		activity.userInfo = [Pin.UserInfoKeys.pin: Pin(containers: documentContainers, document: document).userInfo]
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
