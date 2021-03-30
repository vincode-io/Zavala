//
//  RowContainer.swift
//  
//
//  Created by Maurice Parker on 11/22/20.
//

import Foundation

public protocol RowContainer {
	var rows: [Row] { get }
	var rowCount: Int { get }

	func containsRow(_: Row) -> Bool
	func insertRow(_: Row, at: Int)
	func removeRow(_: Row)
	func appendRow(_: Row)
	func firstIndexOfRow(_: Row) -> Int?

	func print(indentLevel: Int) -> NSAttributedString
	func string(indentLevel: Int) -> String
	func markdownOutline(indentLevel: Int) -> String
	func markdownPost(indentLevel: Int) -> String
	func opml(indentLevel: Int) -> String
}
