//
//  EditorRowPreviewParameters.swift
//  Zavala
//
//  Created by Maurice Parker on 12/4/20.
//

import UIKit
import Templeton

class EditorRowPreviewParameters: UIDragPreviewParameters {
	
	override init() {
		super.init()
	}
	
	init(cell: EditorRowViewCell, row: Row, isCompact: Bool) {
		super.init()

		let topicSize = cell.topicTextView!.bounds.size

		let x: CGFloat
		if isCompact {
			x = CGFloat(4) + (CGFloat(cell.indentationLevel) * cell.indentationWidth)
		} else {
			x = CGFloat(6) + (CGFloat(cell.indentationLevel + 1) * cell.indentationWidth)
		}
		
		let width = topicSize.width + 4
		let height = topicSize.height + 4

		let newBounds = CGRect(x: x, y: 6, width: width, height: height)
		let visiblePath = UIBezierPath(roundedRect: newBounds, cornerRadius: 4)
		self.visiblePath = visiblePath

	}

}
