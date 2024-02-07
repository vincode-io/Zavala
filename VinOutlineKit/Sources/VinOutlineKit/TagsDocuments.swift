//
//  TagsDocuments.swift
//  
//
//  Created by Maurice Parker on 11/7/21.
//

import Foundation

public final class TagsDocuments: DocumentProvider {
    
    private let tags: [Tag]

	public var documents: [Document] {
		let documents = AccountManager.shared.activeDocuments
		return documents.filter { $0.hasAllTags(tags) }
	}

    public init(tags: [Tag]) {
        self.tags = tags
    }
    
}
