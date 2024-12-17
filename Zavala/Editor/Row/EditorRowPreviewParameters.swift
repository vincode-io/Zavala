//
//  EditorRowPreviewParameters.swift
//  Zavala
//
//  Created by Maurice Parker on 12/4/20.
//

import UIKit
import VinOutlineKit

class EditorRowPreviewParameters: UIDragPreviewParameters {
	
	override init() {
		super.init()
	}
	
	init(cell: EditorRowViewCell) {
		super.init()

		let x = CGFloat(6) + (CGFloat(cell.indentationLevel + 1) * cell.indentationWidth)
		let y: CGFloat = switch AppDefaults.shared.rowSpacingSize {
		case .small:
			1
		case .medium:
			2
		case .large:
			4
		}
		
		let topicSize = cell.topicTextView!.bounds.size
		let width = topicSize.width + 12
		let height = topicSize.height + 4

		let newBounds = CGRect(x: x, y: y, width: width, height: height)
		let visiblePath = UIBezierPath(roundedRect: newBounds, cornerRadius: 6)
		self.visiblePath = visiblePath

	}

}
