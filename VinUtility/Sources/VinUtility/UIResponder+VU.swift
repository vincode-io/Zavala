//
//  UIResponder+.swift
//
//  Created by Maurice Parker on 11/17/20.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

#if canImport(UIKit)
import UIKit

extension UIResponder {
	
	private weak static var _currentFirstResponder: UIResponder? = nil

	@available(iOSApplicationExtension, unavailable)
	public static var isFirstResponderTextField: Bool {
		var isTextField = false
		if let firstResponder = UIResponder.currentFirstResponder {
			isTextField = firstResponder.isKind(of: UITextField.self) || firstResponder.isKind(of: UITextView.self) || firstResponder.isKind(of: UISearchBar.self)
		}

		return isTextField
	}

	@available(iOSApplicationExtension, unavailable)
	public static var currentFirstResponder: UIResponder? {
		UIResponder._currentFirstResponder = nil
		UIApplication.shared.sendAction(#selector(findFirstResponder(sender:)), to: nil, from: nil, for: nil)
		return UIResponder._currentFirstResponder
	}
	
	@available(iOSApplicationExtension, unavailable)
	public static func resignCurrentFirstResponder() {
		if let responder = currentFirstResponder {
			responder.resignFirstResponder()
		}
	}

	@objc internal func findFirstResponder(sender: AnyObject) {
		UIResponder._currentFirstResponder = self
	}
	
}
#endif
