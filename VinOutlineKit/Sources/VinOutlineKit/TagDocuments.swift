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
	public var name: String?
	public var partialName: String?

	#if canImport(UIKit)
	#if targetEnvironment(macCatalyst)
	public var image: UIImage? = UIImage(systemName: "capsule")!.applyingSymbolConfiguration(.init(pointSize: 12))
	#else
	public var image: UIImage? = UIImage(systemName: "capsule")!.applyingSymbolConfiguration(.init(pointSize: 15))
	#endif
	#endif

	public var itemCount: Int? {
		guard let tag else { return nil }
		var count = account?.documents?.filter({ $0.hasTag(tag) }).count ?? 0
		
		for child in children {
			count += child.itemCount ?? 0
		}
		
		return count
	}
	
	public var children = [DocumentContainer]()
	
	public weak var account: Account?
	public weak var tag: Tag?
	
	public var documents: [Document] {
		get async throws {
			guard let tag, let documents = account?.documents else { return [] }
			var docs = Set(documents.filter { $0.hasTag(tag) })
			
			for child in children {
				docs.formUnion(try await child.documents)
			}
			
			return Array(docs)
		}
	}

	public init(account: Account, tag: Tag) {
		self.id = .tagDocuments(account.id.accountID, tag.id)
		self.account = account
		self.tag = tag
		self.name = tag.name
		self.partialName = tag.partialName

		guard let name, let accountTags = account.tags else {
			return
		}
		
		let suffix = "\(name)/"
		
		for tag in accountTags {
			if let range = tag.name.range(of: suffix) {
				if !tag.name[range.upperBound...].contains("/") {
					children.append(TagDocuments(account: account, tag: tag))
				}
			}
		}
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

