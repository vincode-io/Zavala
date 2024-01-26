//
//  Created by Maurice Parker on 1/26/24.
//

import Foundation

public final class ReplaceSearchResultCommand: OutlineCommand {

	private let coordinates: [SearchResultCoordinates]
	private let replacementText: String
	private var oldRowStrings = [(Row, RowStrings)]()
	private var oldRangeLength: Int?
	
	public init(actionName: String,
				undoManager: UndoManager,
				delegate: OutlineCommandDelegate,
				outline: Outline,
				coordinates: [SearchResultCoordinates],
				replacementText: String) {

		self.coordinates = coordinates
		self.replacementText = replacementText
		
		for coordinate in coordinates {
			oldRowStrings.append((coordinate.row, coordinate.row.rowStrings))
		}
		
		if let length = coordinates.first?.range.length {
			oldRangeLength = length
		}
		
		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)

	}
	
	public override func perform() {
		saveCursorCoordinates()
		outline.replaceSearchResults(coordinates, with: replacementText)
		registerUndo()
	}
	
	public override func undo() {
		for coordinate in coordinates {
			coordinate.range.length = oldRangeLength ?? 0
		}
		
		for (row, rowStrings) in oldRowStrings {
			outline.updateRow(row, rowStrings: rowStrings, applyChanges: true)
		}
		
		registerRedo()
		restoreCursorPosition()
	}
	
}
