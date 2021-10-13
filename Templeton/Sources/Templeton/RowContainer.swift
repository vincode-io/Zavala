//
//  RowContainer.swift
//  
//
//  Created by Maurice Parker on 11/22/20.
//

import Foundation

public protocol RowContainer {
	var outline: Outline? { get }
	var rows: [Row] { get }
	var rowCount: Int { get }

	func containsRow(_: Row) -> Bool
	func insertRow(_: Row, at: Int)
	func removeRow(_: Row)
	func appendRow(_: Row)
	func firstIndexOfRow(_: Row) -> Int?
}
