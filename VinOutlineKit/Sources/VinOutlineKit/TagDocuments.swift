//
//  TagDocuments.swift
//  
//
//  Created by Maurice Parker on 2/2/21.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

public final class TagDocuments: Identifiable, DocumentContainer {
	
	public var id: EntityID
	
	public var name: String? {
		return tag?.name
	}
	
	public var partialName: String? {
		return tag?.partialName
	}

	#if canImport(UIKit)
	#if targetEnvironment(macCatalyst)
	public var image: UIImage? {
		if children.isEmpty {
			return UIImage(systemName: "capsule")!.applyingSymbolConfiguration(.init(pointSize: 12, weight: .medium))
		} else {
			return UIImage(named: "Tags")!.applyingSymbolConfiguration(.init(pointSize: 16, weight: .regular, scale: .small))
		}
	}
	#else
	public var image: UIImage? {
		if children.isEmpty {
			return UIImage(systemName: "capsule")!.applyingSymbolConfiguration(.init(pointSize: 15, weight: .medium))
		} else {
			return UIImage(named: "Tags")!.applyingSymbolConfiguration(.init(pointSize: 25, weight: .regular, scale: .small))
		}
	}
	#endif
	#endif

	public var itemCount: Int? {
		documents.count
	}
	
	public var ancestors: [DocumentContainer] {
		guard let account else { return [] }
		
		var result = [DocumentContainer]()

		var parentTagName = tag?.parentName
		while (parentTagName != nil) {
			if let parentTag = account.findTag(name: parentTagName!) {
				result.append(TagDocuments(account: account, tag: parentTag))
				parentTagName = parentTag.parentName
			} else {
				// This should never happen. I'm just being paranoid.
				parentTagName = nil
			}
		}
		
		return result
	}
	
	public var children: [DocumentContainer] {
		guard let account, let tag, let accountTags = account.tags else {
			return []
		}
		
		var result = [DocumentContainer]()
		
		for accountTag in accountTags {
			if accountTag.isChild(of: tag) {
				result.append(TagDocuments(account: account, tag: accountTag))
			}
		}
		
		return result
	}
	
	public weak var account: Account?
	public weak var tag: Tag?
	
	public var documents: [Document] {
		guard let tag, let documents = account?.documents else { return [] }
		var docs = Set(documents.filter { $0.hasTag(tag) })
		
		for case let child as TagDocuments in children {
			docs.formUnion(child.documents)
		}
		
		return Array(docs)
	}

	public init(account: Account, tag: Tag) {
		self.id = .tagDocuments(account.id.accountID, tag.id)
		self.account = account
		self.tag = tag
	}
	
	public func hasDecendent(_ entityID: EntityID) -> Bool {
		func decendentCheck(_ docContainer: DocumentContainer) -> Bool {
			if docContainer.id == entityID {
				return true
			}
			for child in docContainer.children {
				if decendentCheck(child) {
					return true
				}
			}
			return false
		}
		
		for child in children {
			if decendentCheck(child) {
				return true
			}
		}
		return false
	}

}

