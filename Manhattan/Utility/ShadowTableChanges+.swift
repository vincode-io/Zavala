//
//  ShadowTableChanges+.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/7/20.
//

import Foundation
import Templeton

extension ShadowTableChanges {
	
	public var deleteIndexPaths: [IndexPath]? {
		guard let deletes = deletes else { return nil }
		return deletes.map { IndexPath(row: $0, section: 1) }
	}
	
	public var insertIndexPaths: [IndexPath]? {
		guard let inserts = inserts else { return nil }
		return inserts.map { IndexPath(row: $0, section: 1) }
	}
	
	public var moveIndexPaths: [(IndexPath, IndexPath)]? {
		guard let moves = moves else { return nil }
		return moves.map { (IndexPath(row: $0.from, section: 1), IndexPath(row: $0.to, section: 1)) }
	}
	
	public var reloadIndexPaths: [IndexPath]? {
		guard let reloads = reloads else { return nil }
		return reloads.map { IndexPath(row: $0, section: 1) }
	}
	
}
