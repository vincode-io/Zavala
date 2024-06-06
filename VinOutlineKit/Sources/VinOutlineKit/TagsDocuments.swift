//
//  TagsDocuments.swift
//  
//
//  Created by Maurice Parker on 11/7/21.
//

import Foundation

public final class TagsDocuments: DocumentProvider {
    
    private let containers: [DocumentContainer]

	public var documents: [Document] {
		get async throws {
			var documents = [Document]()

			for container in containers {
				documents.append(contentsOf: try await container.documents)
			}

			let tags = containers.tags
			return documents.filter { $0.hasAllTags(tags) }
		}
	}

    public init(containers: [DocumentContainer]) {
        self.containers = containers
    }
    
}
