//
//  IndexRequestHandler.swift
//  SpotlightIndexExtension
//
//  Created by Maurice Parker on 3/10/21.
//

import Foundation
import OSLog
@preconcurrency import CoreSpotlight
import VinOutlineKit

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Zavala")

final class IndexRequestHandler: CSIndexExtensionRequestHandler {
	
    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping @Sendable () -> Void) {
		logger.info("IndexRequestHandler starting...")

		Task { @MainActor in
			
			Self.resume()

			for document in AccountManager.shared.documents {
				logger.info("IndexRequestHandler indexing \(document.title ?? "", privacy: .public).")
				
				let documentIndexAttributes = DocumentIndexAttributes(document: document)
				try? await searchableIndex.indexSearchableItems([documentIndexAttributes.searchableItem])
			}
			
			await Self.suspend()
			logger.info("IndexRequestHandler done.")
			acknowledgementHandler()
		}
    }
    
	override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping @Sendable () -> Void) {
		logger.info("IndexRequestHandler starting...")

		Task { @MainActor in
			
			Self.resume()
			
			for description in identifiers {
				if let entityID = EntityID(description: description), let document = AccountManager.shared.findDocument(entityID) {
					
					logger.info("IndexRequestHandler indexing \(document.title ?? "", privacy: .public).")
					
					let documentIndexAttributes = DocumentIndexAttributes(document: document)
					try? await searchableIndex.indexSearchableItems([documentIndexAttributes.searchableItem])
				}
			}

			await Self.suspend()
			logger.info("IndexRequestHandler done.")
			acknowledgementHandler()
		}
	}
	
}

// MARK: ErrorHandler

final class IndexRequestHandlerErrorHandler: ErrorHandler {
	
	func presentError(_ error: Error, title: String) {
		logger.error("IndexRequestHandler failed with error: \(error.localizedDescription, privacy: .public)")
	}
	
}

// MARK: Helpers

private extension IndexRequestHandler {
	
	static let errorHandler = IndexRequestHandlerErrorHandler()
	
	@MainActor
	static func resume() {
		if AccountManager.shared == nil {
			let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as! String
			let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
			let documentAccountsFolderPath = containerURL!.appendingPathComponent("Accounts").path
			AccountManager.shared = AccountManager(accountsFolderPath: documentAccountsFolderPath, errorHandler: Self.errorHandler)
		} else {
			AccountManager.shared.resume()
		}
	}
	
	@MainActor
	static func suspend() async {
		await AccountManager.shared.suspend()
	}
	
}
