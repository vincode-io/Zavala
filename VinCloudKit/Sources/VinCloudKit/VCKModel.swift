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

public protocol VCKModel {
	
	var isCloudKit: Bool { get }
	var cloudKitRecordID: CKRecord.ID { get }
	var cloudKitMetaData: Data? { get set }
	
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
	
//	func merge(client: Data?, ancestor: Data?, server: Data?) -> Data? {
//		switch VCKMergeScenario.evaluate(client: client, ancestor: ancestor, server: server) {
//		case .clientWins:
//			return client
//		case .serverWins:
//			return server
//		case .threeWayMerge:
//			guard let clientAttrString = client?.toAttributedString(),
//				  let ancestorAttrString = ancestor?.toAttributedString(),
//				  let serverAttrString = server?.toAttributedString() else {
//				fatalError("We should always have all 3 values for a 3 way merge.")
//			}
//
//			// The client offset changes are used to adjust the merge so that we can more accurately place
//			// any server changes.
//			let clientOffsetChanges = buildClientOffsetChanges(clientAttrString, ancestorAttrString)
//			
//			let serverDiff = serverAttrString.string.difference(from: ancestorAttrString.string).inferringMoves()
//			if !serverDiff.isEmpty {
//				let merged = NSMutableAttributedString(attributedString: clientAttrString)
//				
//				func computeClientOffset(offset: Int, associated: Int?) -> (Int, Int) {
//					let serverOffset = associated ?? offset
//
//					let adjustedOffset: Int
//					if clientOffsetChanges.isEmpty {
//						adjustedOffset = serverOffset
//					} else {
//						let clientOffsetChangesIndex = serverOffset < clientOffsetChanges.count ? serverOffset : clientOffsetChanges.count - 1
//						adjustedOffset = clientOffsetChanges[clientOffsetChangesIndex] + offset
//					}
//					
//					let newOffset = adjustedOffset <= merged.length ? adjustedOffset : merged.length
//					
//					return (serverOffset, newOffset)
//				}
//				
//				for change in serverDiff {
//					switch change {
//					case .insert(let offset, _, let associated):
//						let (serverOffset, newOffset) = computeClientOffset(offset: offset, associated: associated)
//						let serverAttrString = serverAttrString.attributedSubstring(from: NSRange(location: serverOffset, length: 1))
//						merged.insert(serverAttrString, at: newOffset)
//					case .remove(let offset, _, let associated):
//						let (_, newOffset) = computeClientOffset(offset: offset, associated: associated)
//						if newOffset < merged.length {
//							merged.deleteCharacters(in: NSRange(location: newOffset, length: 1))
//						}
//					}
//				}
//				
//				return merged.toData()
//			} else {
//				// I haven't figured out how to merge pure attribute changes if they happen. Client wins in this case.
//				return client
//			}
//		}
//	}
	
	func merge<T>(client: OrderedSet<T>?, ancestor: OrderedSet<T>?, server: OrderedSet<T>?) -> OrderedSet<T> where T:Equatable {
		let mergeClient = client != nil ? Array(client!) : nil
		let mergeAncestor = ancestor != nil ? Array(ancestor!) : nil
		let mergeServer = server != nil ? Array(server!) : nil
		
		guard let merged = merge(client: mergeClient, ancestor: mergeAncestor, server: mergeServer) else { return OrderedSet() }
		
		return OrderedSet(merged)
	}
	
	func merge<T>(client: [T]?, ancestor: [T]?, server: [T]?) -> [T]? where T:Equatable {
		switch VCKMergeScenario.evaluate(client: client, ancestor: ancestor, server: server) {
		case .clientWins:
			return client
		case .serverWins:
			return server
		case .threeWayMerge:
			guard let client, let server, let ancestor else { fatalError("We should always have all 3 values for a 3 way merge.") }
			let diff = server.difference(from: ancestor)
			guard let merged = client.applying(diff) else {
				return client
			}
			return merged
		}
	}
}

private extension VCKModel {
	
	func buildClientOffsetChanges(_ clientAttrString: NSAttributedString, _ ancestorAttrString: NSAttributedString) -> [Int] {
		var clientOffsetChanges = [Int]()
		
		let clientDiff = clientAttrString.string.difference(from: ancestorAttrString.string)
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
