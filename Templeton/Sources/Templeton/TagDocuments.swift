//
//  TagDocuments.swift
//  
//
//  Created by Maurice Parker on 2/2/21.
//

import UIKit
import RSCore

public final class TagDocuments: Identifiable, DocumentContainer {

	public var id: EntityID
	public var name: String?
	public var image: RSImage? = UIImage(systemName: "capsule")!

	public weak var account: Account?
	public weak var tag: Tag?
	
	public init(account: Account, tag: Tag) {
		self.id = .tagDocuments(account.id.accountID, tag.id)
		self.account = account
		self.tag = tag
		self.name = tag.name
	}
	
	public func sortedDocuments(completion: @escaping (Result<[Document], Error>) -> Void) {
		guard let tag = tag else {
			completion(.success([Document]()))
			return
		}
		
		let tagDocuments = account?.documents?.filter { $0.hasTag(tag) }
		let sortedDocuments = Self.sortByTitle(tagDocuments ?? [Document]())
		completion(.success(sortedDocuments))
	}
	
}
