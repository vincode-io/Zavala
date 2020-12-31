//
//  RemoteDropRowCommand.swift
//  
//
//  Created by Maurice Parker on 12/30/20.
//

import Foundation
import RSCore

public final class RemoteDropRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var changes: ShadowTableChanges?

	var outline: Outline
	var rowMoves = [Outline.RowMove]()
	var restoreMoves = [Outline.RowMove]()
	
	public init(undoManager: UndoManager,
		 delegate: OutlineCommandDelegate,
		 outline: Outline,
		 rows: [Row],
		 toParent: RowContainer,
		 toChildIndex: Int) {
		
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.undoActionName = L10n.copy
		self.redoActionName = L10n.copy
	}
	
	public func perform() {
		saveCursorCoordinates()
		changes = outline.moveRows(rowMoves, textRowStrings: nil)
		registerUndo()
	}
	
	public func undo() {
		let changes = outline.moveRows(restoreMoves, textRowStrings: nil)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}
