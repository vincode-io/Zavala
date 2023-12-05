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
	
	func merge(client: Data?, ancestor: Data?, server: Data?) -> Data? {
		switch VCKMergeScenario.evaluate(client: client, ancestor: ancestor, server: server) {
		case .clientWins:
			return client
		case .serverWins:
			return server
		case .threeWayMerge:
			guard let clientAttrString = client?.toAttributedString(),
				  let serverAttrString = server?.toAttributedString(),
				  let ancestorAttrString = ancestor?.toAttributedString() else {
				fatalError("We should always have all 3 values for a 3 way merge.")
			}
			
			let diff = serverAttrString.string.difference(from: ancestorAttrString.string).inferringMoves()
			if !diff.isEmpty {
				let merged = NSMutableAttributedString(attributedString: clientAttrString)
				
				for change in diff {
					switch change {
					case .insert(let offset, _, let associated):
						let serverAttrString = serverAttrString.attributedSubstring(from: NSRange(location: associated ?? offset, length: 1))
						merged.insert(serverAttrString, at: offset)
					case .remove(let offset, _, _):
						merged.deleteCharacters(in: NSRange(location: offset, length: 1))
					}
				}
				
				return merged.toData()
			} else {
				// TODO: Merge attributes only...
			}
			
			return client
		}
	}
	
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
