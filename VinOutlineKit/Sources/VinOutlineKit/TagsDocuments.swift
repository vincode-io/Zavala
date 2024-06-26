//
//  TagsDocuments.swift
//  
//
//  Created by Maurice Parker on 11/7/21.
//

import Foundation

@MainActor
public final class TagsDocuments: DocumentProvider {
    
    private let containers: [DocumentContainer]

	public var documents: [Document] {
		var intersection: Set<Document>?
		
		for case let container as TagDocuments in containers {
			if let work = intersection {
				intersection = work.intersection(container.documents)
			} else {
				intersection = Set(container.documents)
			}
		}
		
		return Array(intersection ?? Set<Document>())
	}

    public init(containers: [DocumentContainer]) {
        self.containers = containers
    }
    
}
