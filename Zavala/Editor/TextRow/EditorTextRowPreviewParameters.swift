//
//  EditorTextRowPreviewParameters.swift
//  Zavala
//
//  Created by Maurice Parker on 12/4/20.
//

import UIKit
import Templeton

class EditorTextRowPreviewParameters: UIDragPreviewParameters {
	
	override init() {
		super.init()
	}
	
	init(cell: EditorTextRowViewCell, row: TextRow) {
		super.init()

//		#if !targetEnvironment(macCatalyst)
		let x = CGFloat(11 + (cell.indentationLevel * 10))
		
		let cellSize = cell.topicTextView?.intrinsicContentSize ?? cell.bounds.size
		let height = cellSize.height + 4
		let width = cellSize.width + 12
		
		let newBounds = CGRect(x: x, y: 6, width: width, height: height)
		let visiblePath = UIBezierPath(roundedRect: newBounds, cornerRadius: 4)
		self.visiblePath = visiblePath
//		#endif
	}

}
