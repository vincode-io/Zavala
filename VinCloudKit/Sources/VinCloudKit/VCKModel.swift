//
//  VCKModel.swift
//  
//
//  Created by Maurice Parker on 3/18/23.
//

import Foundation
import CloudKit
import OrderedCollections

enum VCKMergeScenario {
	case clientWins
	case serverWins
	case threeWayMerge
	
	static func evaluate<T>(client: T?, ancestor: T?, server: T?) -> Self where T:Equatable {
		if let ancestor {
			// If the value was deleted or is the same as before the client change, client wins
			guard let server, server != ancestor else { return .clientWins }
			
			// The client is trying to delete, but the server has newer value
			guard client != nil else { return .serverWins }
			
			// We have all 3 values and need to do a 3 way merge
			return .threeWayMerge
		} else {
			if server == nil {
				return .clientWins
			} else {
				return .serverWins
			}
		}
	}
}

@MainActor
public protocol VCKModel: Sendable {
	
	var isCloudKit: Bool { get }
	var cloudKitRecordID: CKRecord.ID { get }
	var cloudKitMetaData: Data? { get set }
	var isCloudKitMerging: Bool { get set }
	
	func apply(_ error: CKError)
	func buildRecord() -> CKRecord
	func clearSyncData()
	
}

public extension VCKModel {
	
	func merge<T>(client: T?, ancestor: T?, server: T?) -> T? where T:Equatable {
		switch VCKMergeScenario.evaluate(client: client, ancestor: ancestor, server: server) {
		case .clientWins:
			return client
		case .serverWins:
			return server
		case .threeWayMerge:
			return client
		}
	}
	
	#if canImport(UIKit)
	func merge(client: NSAttributedString?, ancestor: NSAttributedString?, server: NSAttributedString?) -> NSAttributedString? {
		switch VCKMergeScenario.evaluate(client: client, ancestor: ancestor, server: server) {
		case .clientWins:
			return client
		case .serverWins:
			return server
		case .threeWayMerge:
			guard let client, let ancestor, let server else {
				fatalError("We should always have all 3 values for a 3 way merge.")
			}

			let clientOffsetChanges = buildClientOffsetChanges(client.string, ancestor.string)
			
			let serverDiff = server.string.difference(from: ancestor.string).inferringMoves()
			let merged = NSMutableAttributedString(attributedString: client)
				
			for change in serverDiff {
				switch change {
				case .insert(let offset, _, let associated):
					let (serverOffset, newOffset) = computeClientOffset(clientOffsetChanges: clientOffsetChanges, maxLength: merged.length, offset: offset, associated: associated)
					let serverAttrString = server.attributedSubstring(from: NSRange(location: serverOffset, length: 1))
					merged.insert(serverAttrString, at: newOffset)
				case .remove(let offset, _, let associated):
					let (_, newOffset) = computeClientOffset(clientOffsetChanges: clientOffsetChanges, maxLength: merged.length, offset: offset, associated: associated)
					if newOffset < merged.length {
						merged.deleteCharacters(in: NSRange(location: newOffset, length: 1))
					}
				}
			}
				
			return merged
		}
	}
	#endif
	
	func merge<T>(client: OrderedSet<T>?, ancestor: OrderedSet<T>?, server: OrderedSet<T>?) -> OrderedSet<T> where T:Equatable {
		let mergeClient = client != nil ? Array(client!) : nil
		let mergeAncestor = ancestor != nil ? Array(ancestor!) : nil
		let mergeServer = server != nil ? Array(server!) : nil
		
		guard let merged = merge(client: mergeClient, ancestor: mergeAncestor, server: mergeServer) else { return OrderedSet() }
		
		return OrderedSet(merged)
	}
	
	func merge<T>(client: [T]?, ancestor: [T]?, server: [T]?) -> [T]? where T:Equatable, T:Hashable {
		switch VCKMergeScenario.evaluate(client: client, ancestor: ancestor, server: server) {
		case .clientWins:
			return client
		case .serverWins:
			return server
		case .threeWayMerge:
			guard let client, let ancestor, let server else { fatalError("We should always have all 3 values for a 3 way merge.") }

			let clientOffsetChanges = buildClientOffsetChanges(client, ancestor)
			var merged = client
			let diffs = server.difference(from: ancestor).inferringMoves()
			
			for diff in diffs {
				switch diff {
				case .insert(let offset, let value, let associated):
					let (_, newOffset) = computeClientOffset(clientOffsetChanges: clientOffsetChanges, maxLength: merged.count, offset: offset, associated: associated)
					merged.insert(value, at: newOffset)
				case .remove(_, let value, _):
					merged.removeFirst(object: value)
				}
			}

			return merged
		}
	}
	
}

private extension VCKModel {
	
	// The client offset changes are used to adjust the merge so that we can more accurately place
	// any server changes.
	func buildClientOffsetChanges<T>(_ client: T, _ ancestor: T) -> [Int]  where T:BidirectionalCollection, T.Element:Equatable {
		var clientOffsetChanges = [Int]()
		
		let clientDiff = client.difference(from: ancestor)
		var adjuster = 0
		for change in clientDiff {
			switch change {
			case .insert(let offset, _, _):
				while clientOffsetChanges.count < offset {
					clientOffsetChanges.append(clientOffsetChanges.last ?? 0)
				}
				adjuster += 1
				clientOffsetChanges.append(adjuster)
			case .remove(let offset, _, _):
				while clientOffsetChanges.count <= offset {
					clientOffsetChanges.append(clientOffsetChanges.last ?? 0)
				}
				adjuster -= 1
				clientOffsetChanges.append(adjuster)
			}
		}
		
		return clientOffsetChanges
	}

	func computeClientOffset(clientOffsetChanges: [Int], maxLength: Int, offset: Int, associated: Int?) -> (Int, Int) {
		let serverOffset = associated ?? offset

		let adjustedOffset: Int
		if clientOffsetChanges.isEmpty {
			adjustedOffset = serverOffset
		} else {
			let clientOffsetChangesIndex = serverOffset < clientOffsetChanges.count ? serverOffset : clientOffsetChanges.count - 1
			adjustedOffset = clientOffsetChanges[clientOffsetChangesIndex] + offset
		}
		
		let newOffset = adjustedOffset <= maxLength ? adjustedOffset : maxLength
		
		return (serverOffset, newOffset)
	}
	
}

public struct CloudKitModelRecordWrapper: VCKModel {

	private let wrapped: CKRecord
	
	public var isCloudKit: Bool {
		return true
	}
	
	public var cloudKitRecordID: CKRecord.ID {
		return wrapped.recordID
	}
	
	public var cloudKitMetaData: Data? = nil
	public var isCloudKitMerging: Bool = false

	public init(_ wrapped: CKRecord) {
		self.wrapped = wrapped
	}
	
	public func apply(_: CKRecord) { }
	
	public func apply(_ error: CKError) { }
	
	public func buildRecord() -> CKRecord {
		return wrapped
	}
	
	public func clearSyncData() { }

}
