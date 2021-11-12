//
//  UITextView+.swift
//  Zavala
//
//  Created by Maurice Parker on 10/8/21.
//

import UIKit

extension UITextView {
	
	func generatePDF() -> Data {
		let pageRenderer = UIPrintPageRenderer()
		pageRenderer.addPrintFormatter(viewPrintFormatter(), startingAtPageAt: 0)
		return pageRenderer.generatePDF()
	}
	
	func firstRect(for range: NSRange) -> CGRect? {
		guard let start = position(from: beginningOfDocument, offset: range.location),
			  let end = position(from: start, offset: range.length),
			  let textRange = textRange(from: start, to: end) else { return nil }
		
		return firstRect(for: textRange)
	}
	
}
