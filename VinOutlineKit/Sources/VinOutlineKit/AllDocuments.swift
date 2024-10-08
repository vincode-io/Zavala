//
//  AccountDocuments.swift
//  
//
//  Created by Maurice Parker on 1/27/21.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif
public final class AllDocuments: Identifiable, DocumentContainer {
	
	public var documents: [Document] {
		return account?.documents ?? []
	}
	
	public let id: EntityID
	public var name: String? = VinOutlineKitStringAssets.all
	public var partialName: String? = VinOutlineKitStringAssets.all
	
#if canImport(UIKit)
	public var image: UIImage? = UIImage(systemName: "tray")!.applyingSymbolConfiguration(.init(weight: .medium))
#endif
	
	public var itemCount: Int? {
		return account?.documents?.count
	}
	
	public var ancestors: [DocumentContainer] = []
	public var children: [DocumentContainer] = []
	
	public weak var account: Account?
	
	public init(account: Account) {
		self.id = .allDocuments(account.id.accountID)
		self.account = account
	}
	
	public func hasDecendent(_ entityID: EntityID) -> Bool {
		return false
	}
	
}
