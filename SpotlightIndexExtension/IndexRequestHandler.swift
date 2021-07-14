//
//  IndexRequestHandler.swift
//  SpotlightIndexExtension
//
//  Created by Maurice Parker on 3/10/21.
//

import Foundation
import CoreSpotlight
import Templeton

class IndexRequestHandler: CSIndexExtensionRequestHandler {
	
    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
		DispatchQueue.main.async {
			self.resume()
			
			var searchableItems = [CSSearchableItem]()
			for document in AccountManager.shared.documents {
				searchableItems.append(DocumentIndexer.makeSearchableItem(forDocument: document))
			}
			
			self.suspend()
			
			searchableIndex.indexSearchableItems(searchableItems) { _ in
				acknowledgementHandler()
			}
		}
    }
    
	override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
		DispatchQueue.main.async {
			self.resume()
			
			var searchableItems = [CSSearchableItem]()
			for description in identifiers {
				if let entityID = EntityID(description: description), let document = AccountManager.shared.findDocument(entityID) {
					searchableItems.append(DocumentIndexer.makeSearchableItem(forDocument: document))
				}
			}
			
			self.suspend()
			
			searchableIndex.indexSearchableItems(searchableItems) { _ in
				acknowledgementHandler()
			}
		}
	}
	
}

extension IndexRequestHandler {
	
	private func resume() {
		if AccountManager.shared == nil {
			let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as! String
			let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
			let documentAccountsFolderPath = containerURL!.appendingPathComponent("Accounts").path
			AccountManager.shared = AccountManager(accountsFolderPath: documentAccountsFolderPath)
		} else {
			AccountManager.shared.resume()
		}
	}
	
	private func suspend() {
		AccountManager.shared.suspend()
	}
	
}
