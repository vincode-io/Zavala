//
//  File.swift
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
	
	var isSmartProvider: Bool { get } 
	var outlines: [Document]? { get }
	var sortedOutlines: [Document] { get }
}

public extension DocumentContainer {
	
	var isSmartProvider: Bool {
		return id.isSmartProvider
	}

	static func sortByUpdate(_ outlines: [Document]) -> [Document] {
		return outlines.sorted(by: { $0.updated ?? Date.distantPast > $1.updated ?? Date.distantPast })
	}

	static func sortByTitle(_ outlines: [Document]) -> [Document] {
		return outlines.sorted(by: { ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedAscending })
	}

}

public struct LazyDocumentContainer: DocumentContainer {
	
	public var id: EntityID
	
	public var name: String? {
		switch id {
		case .all:
			return L10n.providerAll
		case .favorites:
			return L10n.providerFavorites
		case .recents:
			return L10n.providerRecents
		default:
			fatalError()
		}
	}
	
	public var image: RSImage? {
		switch id {
		case .all:
			return RSImage(systemName: "tray")
		case .favorites:
			return RSImage(systemName: "star.circle")
		case .recents:
			return RSImage(systemName: "clock")
		default:
			fatalError()
		}
	}

	public var outlines: [Document]? {
		return outlineCallback()
	}
	
	public var sortedOutlines: [Document] {
		return outlineCallback()
	}
	
	private var outlineCallback: (() -> [Document])
	
	init(id: EntityID, callback: @escaping (() -> [Document])) {
		self.id = id
		self.outlineCallback = callback
	}
	
}
