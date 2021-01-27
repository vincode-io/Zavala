//
//  DocumentContainer.swift
//  
//
//  Created by Maurice Parker on 11/9/20.
//

import Foundation
import RSCore

public protocol DocumentContainer {
	var id: EntityID { get }
	var name: String? { get }
	var image: RSImage? { get }
	
	func sortedDocuments(completion: @escaping (Result<[Document], Error>) -> Void)
}

public extension DocumentContainer {
	
	static func sortByUpdate(_ documents: [Document]) -> [Document] {
		return documents.sorted(by: { $0.updated ?? Date.distantPast > $1.updated ?? Date.distantPast })
	}

	static func sortByTitle(_ documents: [Document]) -> [Document] {
		return documents.sorted(by: { ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedAscending })
	}

}
