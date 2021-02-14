//
//  RowContainer.swift
//  
//
//  Created by Maurice Parker on 11/22/20.
//

import Foundation

public protocol RowContainer {
	var rows: [Row]? { get set }
	
	func containsRow(_: Row) -> Bool
	func insertRow(_: Row, at: Int)
	func removeRow(_: Row)
	func appendRow(_: Row)
	
	func markdown(indentLevel: Int) -> String
	func opml(indentLevel: Int) -> String
}
