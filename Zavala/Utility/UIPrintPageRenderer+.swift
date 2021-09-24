//
//  UIPrintPageRenderer+.swift
//  Zavala
//
//  Created by Maurice Parker on 9/24/21.
//

import UIKit

extension UIPrintPageRenderer {
	
	func generatePDF() -> Data {
		
		let paperRect = CGRect(x: 0, y: 0, width: 612, height: 792)
		setValue(paperRect, forKey: "paperRect")
		let padding: CGFloat = 56
		let printableRect = paperRect.insetBy(dx: padding, dy: padding)
		setValue(printableRect, forKey: "printableRect")
		
		let data = NSMutableData()
		
		UIGraphicsBeginPDFContextToData(data, CGRect(x: 0.0, y: 0.0, width: paperRect.width, height: paperRect.height), nil)
		prepare(forDrawingPages: NSRange(location: 0, length:numberOfPages))
		
		for i in 0..<numberOfPages {
			UIGraphicsBeginPDFPage()
			drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
		}
		
		UIGraphicsEndPDFContext()
		
		return data as Data
	}
	
}
