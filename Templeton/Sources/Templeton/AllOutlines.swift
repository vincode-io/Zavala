//
//  AllOutlines.swift
//  
//
//  Created by Maurice Parker on 1/27/21.
//

import UIKit
import RSCore

public final class AllOutlines: Identifiable, OutlineContainer {

	public var id: EntityID
	public var name: String? = L10n.all
	public var image: RSImage? = UIImage(systemName: "tray")!

	public var itemCount: Int? {
		return account?.outlines?.count
	}
	
	public weak var account: Account?
	
	public init(account: Account) {
		self.id = .allDocuments(account.id.accountID)
		self.account = account
	}
	
	public func sortedOutlines(completion: @escaping (Result<[Outline], Error>) -> Void) {
		let sortedOutlines = Self.sortByTitle(account?.outlines ?? [Outline]())
		completion(.success(sortedOutlines))
	}
	
}
