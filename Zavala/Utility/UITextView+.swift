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
	
}
