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

struct DocumentIndexer {
	
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
	
	private static func makeSearchableItemAttributes(forDocument document: Document) -> CSSearchableItemAttributeSet {
		let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
		attributeSet.title = document.title ?? ""
		if let keywords = document.tags?.map({ $0.name }) {
			attributeSet.keywords = keywords
		}
		attributeSet.relatedUniqueIdentifier = document.id.description
		attributeSet.textContent = document.string
		attributeSet.contentModificationDate = document.updated
		return attributeSet
	}
	
}
