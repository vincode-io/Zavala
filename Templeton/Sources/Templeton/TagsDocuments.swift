//
//  TagsDocuments.swift
//  
//
//  Created by Maurice Parker on 11/7/21.
//

import Foundation

public final class TagsDocuments: DocumentProvider {
    
    private let tags: [Tag]
    
    public init(tags: [Tag]) {
        self.tags = tags
    }
    
    public func documents(completion: @escaping (Result<[Document], Error>) -> Void) {
        let documents = AccountManager.shared.activeDocuments
        let tagDocuments = documents.filter { $0.hasAllTags(tags) }
        completion(.success(tagDocuments))
    }
    
}
