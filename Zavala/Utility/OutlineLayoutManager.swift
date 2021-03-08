//
//  OutlineLayoutManager.swift
//  Zavala
//
//  Created by Maurice Parker on 3/8/21.
//
// https://stackoverflow.com/a/44303971

import UIKit

class OutlineLayoutManager: NSLayoutManager {

	let cornerRadius: CGFloat = 3

	override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {
		let path = CGMutablePath.init()
		
		if rectCount == 1 || (rectCount == 2 && (rectArray[1].maxX < rectArray[0].maxX)) {
			path.addRect(rectArray[0].insetBy(dx: cornerRadius, dy: cornerRadius))
			if rectCount == 2 {
				path.addRect(rectArray[1].insetBy(dx: cornerRadius, dy: cornerRadius))
			}
		} else {
			let lastRect = rectCount - 1
			path.move(to: CGPoint(x: rectArray[0].minX + cornerRadius, y: rectArray[0].maxY + cornerRadius))
			path.addLine(to: CGPoint(x: rectArray[0].minX + cornerRadius, y: rectArray[0].minY + cornerRadius))
			path.addLine(to: CGPoint(x: rectArray[0].maxX - cornerRadius, y: rectArray[0].minY + cornerRadius))
			path.addLine(to: CGPoint(x: rectArray[0].maxX - cornerRadius, y: rectArray[lastRect].minY - cornerRadius))
			path.addLine(to: CGPoint(x: rectArray[lastRect].maxX - cornerRadius, y: rectArray[lastRect].minY - cornerRadius))
			path.addLine(to: CGPoint(x: rectArray[lastRect].maxX - cornerRadius, y: rectArray[lastRect].maxY - cornerRadius))
			path.addLine(to: CGPoint(x: rectArray[lastRect].minX + cornerRadius, y: rectArray[lastRect].maxY - cornerRadius))
			path.addLine(to: CGPoint(x: rectArray[lastRect].minX + cornerRadius, y: rectArray[0].maxY + cornerRadius))
			path.closeSubpath()
		}
		
		color.set()
		
		let ctx = UIGraphicsGetCurrentContext()
		ctx!.setLineWidth(cornerRadius * 2.0)
		ctx!.setLineJoin(.round)
		
		ctx!.setAllowsAntialiasing(true)
		ctx!.setShouldAntialias(true)
		
		ctx!.addPath(path)
		ctx!.drawPath(using: .fillStroke)
	}
	
}
