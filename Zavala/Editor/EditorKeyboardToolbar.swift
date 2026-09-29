//
//  EditorKeyboardToolbar.swift
//  Zavala
//
//  Created by Maurice Parker on 9/29/26.
//

import UIKit

/// The toolbar shown above the software keyboard.
///
/// The keyboard ignores the window's safe area, but the toolbar lays out its items inside it. On displays with
/// a safe area inset along a side edge, like the vertical status bar column on the iPhone Duo's cover display,
/// that leaves the toolbar's items stopping short of the keyboard's edge. Reporting no side insets lets the
/// toolbar span the keyboard's full width.
class EditorKeyboardToolbar: UIToolbar {

	override var safeAreaInsets: UIEdgeInsets {
		var insets = super.safeAreaInsets
		insets.left = 0
		insets.right = 0
		return insets
	}

}
