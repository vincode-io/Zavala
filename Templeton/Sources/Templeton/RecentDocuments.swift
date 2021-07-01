//
//  RecentDocuments.swift
//  
//
//  Created by Maurice Parker on 2/2/21.
//

import UIKit
import RSCore

public final class RecentDocuments: Identifiable, DocumentContainer {

	public var id: EntityID
	public var name: String? = L10n.recent
	public var image: RSImage? = UIImage(systemName: "clock")!

	public var itemCount: Int? {
		return account?.documents?.prefix(10).count
	}
	
	public weak var account: Account?
	
	public init(account: Account) {
		self.id = .recentDocuments(account.id.accountID)
		self.account = account
	}
	
	public func sortedDocuments(completion: @escaping (Result<[Document], Error>) -> Void) {
		let sortedDocuments = Self.sortByUpdate(account?.documents ?? [Document]())
		let suffix = Array(sortedDocuments.prefix(10))
		completion(.success(suffix))
	}
	
}
