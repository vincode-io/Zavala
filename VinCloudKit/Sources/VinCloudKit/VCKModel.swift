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
	case merge
	
	static func evaluate<T>(client: T?, ancestor: T?, server: T?) -> Self where T:Equatable {
		if let ancestor {
			// If the value was deleted or is the same as before the client change, client wins
			guard let server, server != ancestor else { return .clientWins }
			
			// The client is trying to delete, but the server has newer value
			guard client != nil else { return .serverWins }
			
			// We have all 3 values and need to do a 3 way merge
			return .merge
		} else {
			// If the value was deleted or never existed, client wins
			guard server != nil else { return .clientWins }

			// The client is trying to delete, but the server has newer value
			guard client != nil else { return .serverWins }

			// We have both a server and client, try to merge if possible
			return .merge
		}
	}
}

public protocol VCKModel {
	
	var cloudKitRecordID: CKRecord.ID { get }
	var cloudKitMetaData: Data? { get set }
	
	func apply(_: CKRecord)
	func apply(_ error: CKError)
	func buildRecord() -> CKRecord
	func clearSyncData()
	func deleteTempFiles()
	
}

public extension VCKModel {
	
	func merge<T>(client: T?, ancestor: T?, server: T?) -> T? where T:Equatable {
		switch VCKMergeScenario.evaluate(client: client, ancestor: ancestor, server: server) {
		case .clientWins:
			return client
		case .serverWins:
			return server
		case .merge:
			#warning("This should be changed to be smart enough to merge Strings and AttributedStrings")
			// It should be possible to merge using the raw strings and iterating over the diffs to select the attributes
			// to create a merged NSAttributedString
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
		case .merge:
			guard let client, let server else { fatalError("We should always have both a server or client if we are merging") }
			let diff = server.difference(from: ancestor ?? [])
			guard let merged = client.applying(diff) else {
				return client
			}
			return merged
		}
	}
}

public struct CloudKitModelRecordWrapper: VCKModel {
	
	
	private let wrapped: CKRecord
	
	public var cloudKitRecordID: CKRecord.ID {
		wrapped.recordID
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
	public func deleteTempFiles() { }

}
