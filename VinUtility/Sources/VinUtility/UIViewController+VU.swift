//
//  UIViewController+.swift
//
//  Created by Maurice Parker on 4/15/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//
#if canImport(UIKit)
import UIKit
import SwiftUI

public extension UIViewController {
	
	func presentError(_ error: Error, dismiss: (() -> Void)? = nil) {
		presentError(title: "Error", message: error.localizedDescription, dismiss: dismiss)
	}
	
	func presentError(title: String, message: String, dismiss: (() -> Void)? = nil) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let dismissTitle = NSLocalizedString("OK", comment: "OK")
		let dismissAction = UIAlertAction(title: dismissTitle, style: .default) { _ in
			dismiss?()
		}
		alertController.addAction(dismissAction)
		self.present(alertController, animated: true, completion: nil)
	}
	
}

#endif
