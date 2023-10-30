//
//  DocumentContainer.swift
//  
//
//  Created by Maurice Parker on 11/9/20.
//

import UIKit

public protocol DocumentContainer: DocumentProvider {
	var id: EntityID { get }
	var name: String? { get }
	var image: UIImage? { get }
	var itemCount: Int? { get }
	var account: Account? { get }
}

public extension Array where Element == DocumentContainer {
    
    var uniqueAccount: Account? {
        var account: Account? = nil
        for container in self {
            if let account = account, let containerAccount = container.account {
                if account != containerAccount {
                    return nil
                }
            }
            account = container.account
        }
        return account
    }
    
    var tags: [Tag] {
        return self.compactMap { ($0 as? TagDocuments)?.tag }
    }

    var title: String {
        ListFormatter.localizedString(byJoining: self.compactMap({ $0.name }).sorted())
    }
	
}
