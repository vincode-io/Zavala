//
//  DocumentContainer.swift
//  
//
//  Created by Maurice Parker on 11/9/20.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

@MainActor
public protocol DocumentContainer: DocumentProvider {
	var id: EntityID { get }
	var name: String? { get }
	var partialName: String? { get }
	#if canImport(UIKit)
	var image: UIImage? { get }
	#endif
	var itemCount: Int? { get }

	var ancestors: [DocumentContainer] { get }
	var children: [DocumentContainer] { get }
	
	var account: Account? { get }
	
	func hasDecendent(_ entityID: EntityID) -> Bool
}

public extension Array where Element == DocumentContainer {
    
	@MainActor
    var uniqueAccount: Account? {
        var account: Account? = nil
        for container in self {
            if let account, let containerAccount = container.account {
                if account != containerAccount {
                    return nil
                }
            }
            account = container.account
        }
        return account
    }
    
	@MainActor
    var tags: [Tag] {
        return self.compactMap { ($0 as? TagDocuments)?.tag }
    }

	@MainActor
    var title: String {
        ListFormatter.localizedString(byJoining: self.compactMap({ $0.name }).sorted())
    }
	
}
