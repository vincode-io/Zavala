//
//  IndexRequestHandler.swift
//  SpotlightIndexExtension
//
//  Created by Maurice Parker on 3/10/21.
//

import Foundation
import os.log
import CoreSpotlight
import Templeton

class IndexRequestHandler: CSIndexExtensionRequestHandler {
	
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "IndexRequestHandler")

    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
		DispatchQueue.main.async {
			self.resume()

			let group = DispatchGroup()
			
			for document in AccountManager.shared.documents {
				autoreleasepool {
					let searchableItem = DocumentIndexer.makeSearchableItem(forDocument: document)
					group.enter()
					searchableIndex.indexSearchableItems([searchableItem]) { _ in
						group.leave()
					}
				}
			}
			
			group.notify(queue: .main) {
				self.suspend()
				acknowledgementHandler()
			}
		}
    }
    
	override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
		DispatchQueue.main.async {
			self.resume()
			
			let group = DispatchGroup()
			
			for description in identifiers {
				if let entityID = EntityID(description: description), let document = AccountManager.shared.findDocument(entityID) {
					autoreleasepool {
						let searchableItem = DocumentIndexer.makeSearchableItem(forDocument: document)
						group.enter()
						searchableIndex.indexSearchableItems([searchableItem]) { _ in
							group.leave()
						}
					}
				}
			}
			
			group.notify(queue: .main) {
				self.suspend()
				acknowledgementHandler()
			}
		}
	}
	
}

extension IndexRequestHandler: ErrorHandler {
	
	func presentError(_ error: Error, title: String) {
		os_log(.error, log: log, "IndexRequestHandler failed with error: %@.", error.localizedDescription)
	}
	
}

extension IndexRequestHandler {
	
	private func resume() {
		if AccountManager.shared == nil {
			let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as! String
			let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
			let documentAccountsFolderPath = containerURL!.appendingPathComponent("Accounts").path
			AccountManager.shared = AccountManager(accountsFolderPath: documentAccountsFolderPath, errorHandler: self)
		} else {
			AccountManager.shared.resume()
		}
	}
	
	private func suspend() {
		AccountManager.shared.suspend()
	}
	
}
