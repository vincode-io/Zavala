//
//  Created by Maurice Parker on 1/1/25.
//

import UIKit
import VinOutlineKit

class EditorRowNumberingLabel: UILabel {
	
	func update(configuration: EditorRowContentConfiguration) {
		let attrString = if let numbering = configuration.rowOutlineNumbering {
			NSMutableAttributedString(string: numbering)
		} else {
			NSMutableAttributedString()
		}
		
		let fontColor = if configuration.isSelected {
			UIColor.white.withAlphaComponent(0.66)
		} else {
			OutlineFontCache.shared.numberingColor(level: configuration.rowTrueLevel)
		}
		
		var labelAttributes = [NSAttributedString.Key : Any]()
		if configuration.rowIsComplete || configuration.rowIsAnyParentComplete {
			if fontColor.cgColor.alpha > 0.3 {
				labelAttributes[.foregroundColor] = fontColor.withAlphaComponent(0.3)
			} else {
				labelAttributes[.foregroundColor] = fontColor
			}
			accessibilityLabel = .completeAccessibilityLabel
		} else {
			labelAttributes[.foregroundColor] = fontColor
			accessibilityLabel = nil
		}
		
		if configuration.rowIsComplete {
			labelAttributes[.strikethroughStyle] = 1
			if fontColor.cgColor.alpha > 0.3 {
				labelAttributes[.strikethroughColor] = fontColor.withAlphaComponent(0.3)
			} else {
				labelAttributes[.strikethroughColor] = fontColor
			}
		} else {
			labelAttributes[.strikethroughStyle] = 0
		}
		
		labelAttributes[.font] = OutlineFontCache.shared.numberingFont(level: configuration.rowTrueLevel)

		attrString.setAttributes(labelAttributes, range: NSRange(location: 0, length: attrString.length))
		
		attributedText = attrString
	}
	
}
