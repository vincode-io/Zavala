//
//  DocumentIndexer.swift
//  Zavala
//
//  Created by Maurice Parker on 3/10/21.
//

import Foundation
import MobileCoreServices
import VinOutlineKit
import CoreSpotlight

@MainActor
class DocumentIndexer {
	
	/// Lets the app add to a Document's searchable item before it's indexed, and keep additional indexes in sync
	/// when it's removed, without the extensions that share this file needing to know about them.
	static var prepareSearchableItem: (@MainActor (CSSearchableItem, Document) -> Void)?
	static var didRemoveIndex: (@MainActor (Document) -> Void)?

	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(documentDidDelete(_:)), name: .DocumentDidDelete, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentDidChangeBySync(_:)), name: .DocumentDidChangeBySync, object: nil)
	}
	
	static func updateIndex(for document: Document) {
		let searchableItem = DocumentIndexAttributes(document: document).searchableItem
		prepareSearchableItem?(searchableItem, document)
		CSSearchableIndex.default().indexSearchableItems([searchableItem])
	}

	static func removeIndex(for document: Document) {
		CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [document.id.description])
		didRemoveIndex?(document)
	}
	
}

// MARK: Helpers

private extension DocumentIndexer {
	
	@objc func documentDidDelete(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		Self.removeIndex(for: document)
	}

	@objc func documentDidChangeBySync(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		
		if document.isLocked {
			Self.removeIndex(for: document)
		} else {
			Self.updateIndex(for: document)
		}
	}
	
}

struct DocumentIndexAttributes: Sendable {
	
	let title: String
	let keywords: [String]
	let relatedUniqueIdentifier: String
	let textContent: String
	let contentModificationDate: Date
	
	var searchableItem: CSSearchableItem {
		return CSSearchableItem(uniqueIdentifier: relatedUniqueIdentifier, domainIdentifier: "io.vincode", attributeSet: searchableItemAttributeSet)
	}
	
	private var searchableItemAttributeSet: CSSearchableItemAttributeSet {
		let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.text)
		attributeSet.title = title
		attributeSet.keywords = keywords
		attributeSet.relatedUniqueIdentifier = relatedUniqueIdentifier
		attributeSet.textContent = textContent
		attributeSet.contentModificationDate = contentModificationDate
		return attributeSet
	}
	
	@MainActor
	init(document: Document) {
		title = document.title ?? ""
		keywords = document.tags?.map({ $0.name }) ?? []
		relatedUniqueIdentifier = document.id.description
		textContent = document.textContent
		contentModificationDate = document.updated ?? Date()
	}
	
}
