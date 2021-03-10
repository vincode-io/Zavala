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
	
	override init() {
		DispatchQueue.main.sync {
			let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as! String
			let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
			let documentAccountsFolderPath = containerURL!.appendingPathComponent("Accounts").path
			AccountManager.shared = AccountManager(accountsFolderPath: documentAccountsFolderPath)
		}
	}

    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
		DispatchQueue.main.async {
			var searchableItems = [CSSearchableItem]()
			
			for document in AccountManager.shared.documents {
				searchableItems.append(DocumentIndexer.makeSearchableItem(forDocument: document))
			}
			
			searchableIndex.indexSearchableItems(searchableItems)
			acknowledgementHandler()
		}
    }
    
	override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
		DispatchQueue.main.async {
			var searchableItems = [CSSearchableItem]()
			
			for description in identifiers {
				if let entityID = EntityID(description: description), let document = AccountManager.shared.findDocument(entityID) {
					searchableItems.append(DocumentIndexer.makeSearchableItem(forDocument: document))
				}
			}
			
			searchableIndex.indexSearchableItems(searchableItems)
			acknowledgementHandler()
		}
	}
	
}
