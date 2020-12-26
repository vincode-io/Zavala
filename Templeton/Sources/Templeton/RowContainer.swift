//
//  RowContainer.swift
//  
//
//  Created by Maurice Parker on 11/22/20.
//

import Foundation

public protocol RowContainer {
	var rows: [Row]? { get set }
	func markdown(indentLevel: Int) -> String
	func opml() -> String
}
