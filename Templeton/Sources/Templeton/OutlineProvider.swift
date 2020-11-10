//
//  File.swift
//  
//
//  Created by Maurice Parker on 11/9/20.
//

import Foundation
import RSCore

public enum OutlineProviderID: Hashable, Equatable {
	case all
	case favorites
	case recents
	case folder(Int, String) // Account.ID, Folder.ID
}

public protocol OutlineProvider {
	var outlineProviderID: OutlineProviderID { get }
	var name: String? { get }
	var image: RSImage? { get }
	var outlines: [Outline]? { get }
}

public struct LazyOutlineProvider: OutlineProvider {
	
	public var outlineProviderID: OutlineProviderID
	
	public var name: String? {
		switch outlineProviderID {
		case .all:
			return NSLocalizedString("All", comment: "All")
		case .favorites:
			return NSLocalizedString("Favorites", comment: "Favorites")
		case .recents:
			return NSLocalizedString("Recents", comment: "Recents")
		default:
			fatalError()
		}
	}
	
	public var image: RSImage? {
		switch outlineProviderID {
		case .all:
			return RSImage(systemName: "tray")
		case .favorites:
			return RSImage(systemName: "heart.circle")
		case .recents:
			return RSImage(systemName: "clock")
		default:
			fatalError()
		}
	}
	
	public var outlines: [Outline]? {
		return outlineCallback()
	}
	
	private var outlineCallback: (() -> [Outline])
	
	init(id: OutlineProviderID, callback: @escaping (() -> [Outline])) {
		self.outlineProviderID = id
		self.outlineCallback = callback
	}
	
}
