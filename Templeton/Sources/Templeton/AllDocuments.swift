//
//  AccountDocuments.swift
//  
//
//  Created by Maurice Parker on 1/27/21.
//

import UIKit
import RSCore

public final class AllDocuments: Identifiable, DocumentContainer {

	public var id: EntityID
	public var name: String? = L10n.all
	public var image: RSImage? = UIImage(systemName: "tray")!

	public var itemCount: Int? {
		return account?.documents?.count
	}
	
	public weak var account: Account?
	
	public init(account: Account) {
		self.id = .allDocuments(account.id.accountID)
		self.account = account
	}
	
	public func sortedDocuments(completion: @escaping (Result<[Document], Error>) -> Void) {
		let sortedDocuments = Self.sortByTitle(account?.documents ?? [Document]())
		completion(.success(sortedDocuments))
	}
	
}
