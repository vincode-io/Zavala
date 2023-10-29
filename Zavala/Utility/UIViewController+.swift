//
//  UIViewController+.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import RSCore

extension UIViewController {
	
	func presentError(_ error: Error, dismiss: (() -> Void)? = nil) {
		let errorTitle = AppStringAssets.errorAlertTitle
		presentError(title: errorTitle, message: error.localizedDescription, dismiss: dismiss)
	}

}
