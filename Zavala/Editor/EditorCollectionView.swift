//
//  EditorCollectionView.swift
//  Zavala
//
//  Created by Maurice Parker on 10/18/21.
//

import UIKit

class EditorCollectionView: UICollectionView {

	override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
		// This is disabled to prevent the UITextView from scrolling constantly when we don't want it to
		// https://stackoverflow.com/a/12640831/11330872
	}

	func scrollRectToVisibleBypass(_ rect: CGRect, animated: Bool) {
		super.scrollRectToVisible(rect, animated: animated)
	}

}
