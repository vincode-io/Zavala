//
//  EditorTagPaddedButton.swift
//  Zavala
//
//  Created by Maurice Parker on 8/11/26.
//

import UIKit

/// A tag button that pads its title away from the pill's edges. Replaces the deprecated
/// `contentEdgeInsets` while keeping the button's classic, synchronous title sizing so that
/// the self-sizing tag cell can measure its intrinsic content size correctly.
class EditorTagPaddedButton: UIButton {

	static let defaultTitleInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

	/// The height of a tag button using `font` and the default insets, measured the same way as `intrinsicContentSize`.
	static func defaultHeight(for font: UIFont) -> CGFloat {
		let sizingLabel = UILabel()
		sizingLabel.font = font
		sizingLabel.text = " "
		return sizingLabel.intrinsicContentSize.height + defaultTitleInsets.top + defaultTitleInsets.bottom
	}

	var titleInsets = EditorTagPaddedButton.defaultTitleInsets {
		didSet {
			invalidateIntrinsicContentSize()
		}
	}

	override var intrinsicContentSize: CGSize {
		// Size from the title itself plus our insets so the padding is exactly the insets,
		// rather than adding to whatever content padding the button reserves internally.
		let titleSize = titleLabel?.intrinsicContentSize ?? .zero
		return CGSize(width: titleSize.width + titleInsets.left + titleInsets.right,
					  height: titleSize.height + titleInsets.top + titleInsets.bottom)
	}

}
