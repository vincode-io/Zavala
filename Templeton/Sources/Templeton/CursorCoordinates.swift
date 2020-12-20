//
//  File.swift
//  
//
//  Created by Maurice Parker on 12/20/20.
//

import Foundation

public struct CursorCoordinates {

	public var headline: Headline
	public var isInNotes: Bool
	public var cursorPosition: Int
	
	public init(headline: Headline, isInNotes: Bool, cursorPosition: Int) {
		self.headline = headline
		self.isInNotes = isInNotes
		self.cursorPosition = cursorPosition
	}

}
