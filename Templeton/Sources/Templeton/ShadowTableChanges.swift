//
//  File.swift
//  
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation

public struct ShadowTableChanges {
	
	public struct Move: Hashable {
		var from: Int
		var to: Int
		
		init(_ from: Int, _ to: Int) {
			self.from = from
			self.to = to
		}
	}
	
	public var deletes: Set<Int>?
	public var inserts: Set<Int>?
	public var moves: Set<Move>?
	public var reloads: Set<Int>?
	
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
		return moves.map { (IndexPath(row: $0.from, section: 0), IndexPath(row: $0.to, section: 0)) }
	}
	
	public var reloadIndexPaths: [IndexPath]? {
		guard let reloads = reloads else { return nil }
		return reloads.map { IndexPath(row: $0, section: 0) }
	}
	
	init(deletes: Set<Int>? = nil, inserts: Set<Int>? = nil, moves: Set<Move>? = nil, reloads: Set<Int>? = nil) {
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
				self.deletes!.formUnion(changeDeletes)
			}
		}

		if let changeInserts = changes.inserts {
			if inserts == nil {
				inserts = changeInserts
			} else {
				self.inserts!.formUnion(changeInserts)
			}
		}

		if let changeMoves = changes.moves {
			if moves == nil {
				moves = changeMoves
			} else {
				self.moves!.formUnion(changeMoves)
			}
		}
		
		if let changeReloads = changes.reloads {
			if reloads == nil {
				reloads = changeReloads
			} else {
				self.reloads!.formUnion(changeReloads)
			}
		}
	}
}
