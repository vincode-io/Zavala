//
//  UIScrollView+.swift
//  Zavala
//
//  Created by Maurice Parker on 10/12/26.
//

import UIKit

extension UIScrollView {

	/// Hides the top edge effect while the content is scrolled to the top.
	///
	/// An explicitly hard top edge effect always draws its divider, even when nothing is scrolled under the
	/// navigation bar. The automatic style hides it at the top, so this makes a hard edge effect behave the same.
	func updateTopEdgeEffectVisibility() {
		topEdgeEffect.isHidden = contentOffset.y <= -adjustedContentInset.top
	}

}
