//
//  TagDocuments.swift
//  
//
//  Created by Maurice Parker on 2/2/21.
//

import UIKit

public final class TagDocuments: Identifiable, DocumentContainer {

	public var id: EntityID
	public var name: String?

	#if targetEnvironment(macCatalyst)
	public var image: UIImage? = UIImage(systemName: "capsule")!.applyingSymbolConfiguration(.init(pointSize: 12))
	#else
	public var image: UIImage? = UIImage(systemName: "capsule")!.applyingSymbolConfiguration(.init(pointSize: 15))
	#endif
	
	public var itemCount: Int? {
		guard let tag else { return nil }
		return account?.documents?.filter({ $0.hasTag(tag) }).count
	}
	
	public weak var account: Account?
	public weak var tag: Tag?
	
	public init(account: Account, tag: Tag) {
		self.id = .tagDocuments(account.id.accountID, tag.id)
		self.account = account
		self.tag = tag
		self.name = tag.name
	}
	
	public func documents(completion: @escaping (Result<[Document], Error>) -> Void) {
		guard let tag else {
			completion(.success([Document]()))
			return
		}
		
		let tagDocuments = account?.documents?.filter { $0.hasTag(tag) }
		completion(.success(tagDocuments ?? [Document]()))
	}
	
}
