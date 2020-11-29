//
//  File.swift
//  
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation

public struct ShadowTableChanges {
	
	public var deletes: [Int]?
	public var inserts: [Int]?
	public var moves: [(Int, Int)]?
	public var reloads: [Int]?
	
	public var isEmpty: Bool {
		return deletes == nil && inserts == nil && reloads == nil
	}
	
	public var deleteIndexPaths: [IndexPath]? {
		guard let deletes = deletes else { return nil }
		return deletes.map { IndexPath(row: $0, section: 0) }
	}
	
	public var insertIndexPaths: [IndexPath]? {
		guard let inserts = inserts else { return nil }
		return inserts.map { IndexPath(row: $0, section: 0) }
	}
	
	public var moveIndexPaths: [(IndexPath, IndexPath)]? {
		guard let moves = moves else { return nil }
		return moves.map { (IndexPath(row: $0.0, section: 0), IndexPath(row: $0.1, section: 0)) }
	}
	
	public var reloadIndexPaths: [IndexPath]? {
		guard let reloads = reloads else { return nil }
		return reloads.map { IndexPath(row: $0, section: 0) }
	}
	
	init(deletes: [Int]? = nil, inserts: [Int]? = nil, moves: [(Int, Int)]? = nil, reloads: [Int]? = nil) {
		self.deletes = deletes
		self.inserts = inserts
		self.moves = moves
		self.reloads = reloads
	}
	
	mutating func append(_ changes: ShadowTableChanges) {
		if let changeDeletes = changes.deletes {
			if deletes == nil {
				deletes = changeDeletes
			} else {
				self.deletes!.append(contentsOf: changeDeletes)
			}
		}

		if let changeInserts = changes.inserts {
			if inserts == nil {
				inserts = changeInserts
			} else {
				self.inserts!.append(contentsOf: changeInserts)
			}
		}

		if let changeMoves = changes.moves {
			if moves == nil {
				moves = changeMoves
			} else {
				self.moves!.append(contentsOf: changeMoves)
			}
		}
		
		if let changeReloads = changes.reloads {
			if reloads == nil {
				reloads = changeReloads
			} else {
				self.reloads!.append(contentsOf: changeReloads)
			}
		}
	}
}
