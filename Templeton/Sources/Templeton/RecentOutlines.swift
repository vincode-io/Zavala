//
//  RecentOutlines.swift
//  
//
//  Created by Maurice Parker on 2/2/21.
//

import UIKit
import RSCore

public final class RecentOutlines: Identifiable, OutlineContainer {

	public var id: EntityID
	public var name: String? = L10n.recent
	public var image: RSImage? = UIImage(systemName: "clock")!

	public var itemCount: Int? {
		return account?.outlines?.prefix(10).count
	}
	
	public weak var account: Account?
	
	public init(account: Account) {
		self.id = .recentDocuments(account.id.accountID)
		self.account = account
	}
	
	public func sortedOutlines(completion: @escaping (Result<[Outline], Error>) -> Void) {
		let sortedOutlines = Self.sortByUpdate(account?.outlines ?? [Outline]())
		let suffix = Array(sortedOutlines.prefix(10))
		completion(.success(suffix))
	}
	
}
