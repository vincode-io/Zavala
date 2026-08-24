//
//  FixMacTogglePadding.swift
//  Zavala
//
//  Created by Maurice Parker on 8/24/26.
//

import SwiftUI

/// Removes the extra trailing padding that switch-style toggles pick up on the Mac,
/// keeping them aligned with the other controls in a grouped form.
struct FixMacTogglePadding: ViewModifier {

	func body(content: Content) -> some View {
		content
		#if targetEnvironment(macCatalyst)
			.padding(.trailing, -12)
		#endif
	}

}

extension View {

	/// Removes the extra trailing padding that switch-style toggles pick up on the Mac.
	func fixMacTogglePadding() -> some View {
		modifier(FixMacTogglePadding())
	}

}
