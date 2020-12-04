//
//  EditorCellPreviewParameters.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/4/20.
//

import UIKit
import Templeton

class EditorCellPreviewParameters: UIDragPreviewParameters {
	
	override init() {
		super.init()
	}
	
	init(cell: EditorCollectionViewCell, headline: Headline) {
		super.init()

//		#if !targetEnvironment(macCatalyst)
		let x = CGFloat(11 + (cell.indentationLevel * 10))
		let width = (cell.textWidth ?? cell.bounds.width) + 12
		let newBounds = CGRect(x: x, y: 0, width: width, height: cell.bounds.height)
		let visiblePath = UIBezierPath(roundedRect: newBounds, cornerRadius: 10)
		self.visiblePath = visiblePath
//		#endif
	}

}
