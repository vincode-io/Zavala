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
	
	@MainActor
	static var accountManager: AccountManager?
	
    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping @Sendable () -> Void) {
		logger.info("IndexRequestHandler starting...")

		Task { @MainActor in
			
			Self.resume()

			for document in Self.accountManager?.documents ?? [] {
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
				if let entityID = EntityID(description: description), let document = Self.accountManager?.findDocument(entityID) {
					
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
		if Self.accountManager == nil {
			let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as! String
			let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
			let documentAccountsFolderPath = containerURL!.appendingPathComponent("Accounts").path
			Self.accountManager = AccountManager(accountsFolderPath: documentAccountsFolderPath, errorHandler: Self.errorHandler)
		} else {
			Self.accountManager?.resume()
		}
	}
	
	@MainActor
	static func suspend() async {
		await Self.accountManager?.suspend()
	}
	
}
