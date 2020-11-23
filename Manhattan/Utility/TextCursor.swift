//
//  TextCursor.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

protocol TextCursorTarget {
	func releaseCursor()
	func restoreSelection(_ textRange: UITextRange)
	func moveToEnd()
}

protocol TextCursorSource: UITextView {
	var identifier: Any? { get }
}
