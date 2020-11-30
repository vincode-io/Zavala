//
//  UIView+.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

extension UIView {

	/// Removes all constrains for this view as long as unowned ones only relate to the superview
	func removeConstraintsOwnedBySuperview() {
		let constraints = self.superview?.constraints.filter{
			$0.firstItem as? UIView == self || $0.secondItem as? UIView == self
		} ?? []

		self.superview?.removeConstraints(constraints)
	}
	
}
