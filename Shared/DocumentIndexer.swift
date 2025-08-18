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
	
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(documentDidChangeBySync(_:)), name: .DocumentDidChangeBySync, object: nil)
	}
	
	static func updateIndex(forDocument document: Document) {
		let documentIndexAttributes = DocumentIndexAttributes(document: document)
		CSSearchableIndex.default().indexSearchableItems([documentIndexAttributes.searchableItem])
	}
	
}

// MARK: Helpers

private extension DocumentIndexer {
	
	@objc func documentDidChangeBySync(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		Self.updateIndex(forDocument: document)
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
