//
//  CKRecord.swift
//  
//
//  Created by Maurice Parker on 10/31/22.
//

import Foundation
import CloudKit

extension CKRecord {
	
	public convenience init?(_ data: Data) {
		guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else {
			return nil
		}
		unarchiver.requiresSecureCoding = true
		self.init(coder: unarchiver)
	}
	
	public var metadata: Data {
		get {
			let archiver = NSKeyedArchiver(requiringSecureCoding: true)
			encodeSystemFields(with: archiver)
			return archiver.encodedData
		}
	}

	public func isEqual<T: Equatable>(key: String, valueType: T.Type, other: CKRecord) -> Bool {
		guard let value = object(forKey: key) as? T,
			  let otherValue = other.object(forKey: key) as? T,
			  value == otherValue else { return false }
		return true
	}
	
}
