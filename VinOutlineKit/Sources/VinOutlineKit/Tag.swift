//
//  Tag.swift
//  
//
//  Created by Maurice Parker on 1/28/21.
//

import Foundation
import VinUtility

@MainActor
public class Tag: Identifiable, Equatable {
	
	public let id: String
	public var name: String
	
	public var level: Int {
		name.split(separator: "/").count - 1
	}

	public var partialName: String {
		if let lastElement = name.split(separator: "/").last {
			return String(lastElement)
		}
		return name
	}

	public var parentName: String? {
		guard let index = name.lastIndex(of: "/") else { return nil }
		return String(name[..<index])
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
	}
	
	public init(name: String) {
		self.id = UUID().uuidString
		self.name = name
	}
	
	init(coder: TagCoder) {
		self.id = coder.id
		self.name = coder.name
	}
	
	public func isChild(of tag: Tag) -> Bool {
		let fullName = tag.name + "/" + partialName
		if name == fullName {
			return true
		}
		return false
	}
	
	public func isDecendent(of tag: Tag) -> Bool {
		guard tag.name != name else { return false }
		
		if let range = name.range(of: "\(tag.name)/") {
			if range.lowerBound != tag.name.startIndex {
				return false
			}
			return true
		}
		
		return false
	}
	
	public func renamePath(from: String, to: String) {
		let startIndex = name.index(name.startIndex, offsetBy: from.count)
		let remainder = name[startIndex...]
		name = to.appending(remainder)
	}
	
	func toCoder() -> TagCoder {
		return TagCoder(id: id, name: name)
	}
	
	public static func normalize(name: String) -> String {
		var trimmedElements = [String]()
		let elements = name.split(separator: "/")
		
		for element in elements {
			if let trimmed = String(element).trimmed() {
				trimmedElements.append(trimmed)
			}
		}
		
		return trimmedElements.joined(separator: "/")
	}
	
	nonisolated public static func == (lhs: Tag, rhs: Tag) -> Bool {
		return lhs.id == rhs.id
	}
	
}
