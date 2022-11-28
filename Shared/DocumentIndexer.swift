//
//  DocumentIndexer.swift
//  Zavala
//
//  Created by Maurice Parker on 3/10/21.
//

import Foundation
import MobileCoreServices
import Templeton
import CoreSpotlight

class DocumentIndexer {
	
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(documentDidChangeBySync(_:)), name: .DocumentDidChangeBySync, object: nil)
	}
	
	static func updateIndex(forDocument document: Document) {
		DispatchQueue.main.async {
			let searchableItem = makeSearchableItem(forDocument: document)
			CSSearchableIndex.default().indexSearchableItems([searchableItem])
		}
	}
	
	static func makeSearchableItem(forDocument document: Document) -> CSSearchableItem {
		let attributeSet = makeSearchableItemAttributes(forDocument: document)
		let identifier = attributeSet.relatedUniqueIdentifier
		return CSSearchableItem(uniqueIdentifier: identifier, domainIdentifier: "io.vincode", attributeSet: attributeSet)
	}
	
}

// MARK: Helpers

private extension DocumentIndexer {
	
	static func makeSearchableItemAttributes(forDocument document: Document) -> CSSearchableItemAttributeSet {
		let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
		attributeSet.title = document.title ?? ""
		if let keywords = document.tags?.map({ $0.name }) {
			attributeSet.keywords = keywords
		}
		attributeSet.relatedUniqueIdentifier = document.id.description
		attributeSet.textContent = document.textContent
		attributeSet.contentModificationDate = document.updated
		return attributeSet
	}
	
	@objc func documentDidChangeBySync(_ note: Notification) {
		guard let document = note.object as? Document else { return }
		Self.updateIndex(forDocument: document)
	}
	
}
