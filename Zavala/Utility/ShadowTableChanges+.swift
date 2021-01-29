//
//  ShadowTableChanges+.swift
//  Zavala
//
//  Created by Maurice Parker on 12/7/20.
//

import Foundation
import Templeton

extension ShadowTableChanges {
	
	var isOnlyReloads: Bool {
		return (deletes?.isEmpty ?? true) && (inserts?.isEmpty ?? true) && (moves?.isEmpty ?? true)
	}
	
	public var deleteIndexPaths: [IndexPath]? {
		guard let deletes = deletes else { return nil }
		return deletes.map { IndexPath(row: $0, section: EditorViewController.rowSection) }
	}
	
	public var insertIndexPaths: [IndexPath]? {
		guard let inserts = inserts else { return nil }
		return inserts.map { IndexPath(row: $0, section: EditorViewController.rowSection) }
	}
	
	public var moveIndexPaths: [(IndexPath, IndexPath)]? {
		guard let moves = moves else { return nil }
		return moves.map { (IndexPath(row: $0.from, section: EditorViewController.rowSection), IndexPath(row: $0.to, section: EditorViewController.rowSection)) }
	}
	
	public var reloadIndexPaths: [IndexPath]? {
		guard let reloads = reloads else { return nil }
		return reloads.map { IndexPath(row: $0, section: EditorViewController.rowSection) }
	}
	
}
