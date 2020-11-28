//
//  File.swift
//  
//
//  Created by Maurice Parker on 11/9/20.
//

import Foundation
import RSCore

public protocol OutlineProvider {
	var id: EntityID { get }
	var name: String? { get }
	var image: RSImage? { get }
	
	var isSmartProvider: Bool { get } 
	var outlines: [Outline]? { get }
	var sortedOutlines: [Outline] { get }
}

public extension OutlineProvider {
	
	var isSmartProvider: Bool {
		return id.isSmartProvider
	}

	static func sortByUpdate(_ outlines: [Outline]) -> [Outline] {
		return outlines.sorted(by: { $0.updated ?? Date.distantPast > $1.updated ?? Date.distantPast })
	}

	static func sortByTitle(_ outlines: [Outline]) -> [Outline] {
		return outlines.sorted(by: { ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedAscending })
	}

}

public struct LazyOutlineProvider: OutlineProvider {
	
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

	public var outlines: [Outline]? {
		return outlineCallback()
	}
	
	public var sortedOutlines: [Outline] {
		return outlineCallback()
	}
	
	private var outlineCallback: (() -> [Outline])
	
	init(id: EntityID, callback: @escaping (() -> [Outline])) {
		self.id = id
		self.outlineCallback = callback
	}
	
}
