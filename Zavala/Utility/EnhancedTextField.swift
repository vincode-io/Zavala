//
//  EnhancedTextField.swift
//  Zavala
//
//  Created by Maurice Parker on 3/16/21.
//

import UIKit

open class EnhancedTextField: UITextField {

	open override var keyCommands: [UIKeyCommand]? {
		[
			UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: .shift, action: #selector(shiftUpArrow(_:))),
			UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .shift, action: #selector(shiftDownArrow(_:)))
		]
	}

	/// Whether this field should draw a focus ring when it's being edited.
	///
	/// macOS 26 stopped drawing the automatic focus ring for edited Catalyst text
	/// fields, so we redraw one ourselves via the modern focus-effect API. Subclasses
	/// that shouldn't show a ring (such as a borderless inline field) can override this.
	open var wantsFocusRing: Bool { true }

	#if targetEnvironment(macCatalyst)
	private var focusRingBounds: CGRect = .zero

	open override func layoutSubviews() {
		super.layoutSubviews()

		guard wantsFocusRing else {
			focusEffect = nil
			return
		}

		// The default UIFocusEffect() draws a square halo, so we supply an explicit
		// rounded halo matching the field's laid-out bounds.
		guard bounds != focusRingBounds else { return }
		focusRingBounds = bounds
		focusEffect = UIFocusHaloEffect(roundedRect: bounds, cornerRadius: 6, curve: .continuous)
	}
	#endif

	@objc func shiftUpArrow(_ sender: Any) {
		if let cursor = selectedTextRange?.start {
			selectedTextRange = textRange(from: beginningOfDocument, to: cursor)
		}
	}

	@objc func shiftDownArrow(_ sender: Any) {
		if let cursor = selectedTextRange?.start {
			selectedTextRange = textRange(from: cursor, to: endOfDocument)
		}
	}
}
