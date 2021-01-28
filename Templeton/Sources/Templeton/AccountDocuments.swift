//
//  AccountDocuments.swift
//  
//
//  Created by Maurice Parker on 1/27/21.
//

import UIKit
import RSCore

public final class AccountDocuments: Identifiable, DocumentContainer {

	public var id: EntityID
	public var name: String? = L10n.all
	public var image: RSImage? = UIImage(systemName: "tray")!

	private var account: Account
	
	public init(account: Account) {
		self.id = .accountDocuments(account.id.accountID)
		self.account = account
	}
	
	public func sortedDocuments(completion: @escaping (Result<[Document], Error>) -> Void) {
		let sortedDocuments = Self.sortByTitle(account.documents ?? [Document]())
		completion(.success(sortedDocuments))
	}
	
}
