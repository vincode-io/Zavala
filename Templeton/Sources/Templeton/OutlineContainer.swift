//
//  OutlineContainer.swift
//  
//
//  Created by Maurice Parker on 11/9/20.
//

import Foundation
import RSCore

public protocol OutlineContainer {
	var id: EntityID { get }
	var name: String? { get }
	var image: RSImage? { get }
	var itemCount: Int? { get }
	var account: Account? { get }
	
	func sortedOutlines(completion: @escaping (Result<[Outline], Error>) -> Void)
}

public extension OutlineContainer {
	
	static func sortByUpdate(_ documents: [Outline]) -> [Outline] {
		return documents.sorted(by: { $0.updated ?? Date.distantPast > $1.updated ?? Date.distantPast })
	}

	static func sortByTitle(_ documents: [Outline]) -> [Outline] {
		return documents.sorted(by: { ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedAscending })
	}

}
