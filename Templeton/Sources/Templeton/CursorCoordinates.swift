//
//  File.swift
//  
//
//  Created by Maurice Parker on 12/20/20.
//

import Foundation

public struct CursorCoordinates {

	public var row: TextRow
	public var isInNotes: Bool
	public var cursorPosition: Int
	
	public init(row: TextRow, isInNotes: Bool, cursorPosition: Int) {
		self.row = row
		self.isInNotes = isInNotes
		self.cursorPosition = cursorPosition
	}

}
