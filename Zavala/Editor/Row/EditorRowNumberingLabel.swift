//
//  Created by Maurice Parker on 1/1/25.
//

import UIKit
import VinOutlineKit

class EditorRowNumberingLabel: UILabel {
	
	func update(with row: Row, for numberingStyle: Outline.NumberingStyle) {
		let attrString = if numberingStyle == .decimal {
			NSMutableAttributedString(string: row.decimalNumbering)
		} else {
			NSMutableAttributedString(string: row.legalNumbering)
		}
		
		let fontColor = OutlineFontCache.shared.numberingColor(level: row.trueLevel)
		
		var labelAttributes = [NSAttributedString.Key : Any]()
		if row.isComplete ?? false || row.isAnyParentComplete {
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
		
		if row.isComplete ?? false {
			labelAttributes[.strikethroughStyle] = 1
			if fontColor.cgColor.alpha > 0.3 {
				labelAttributes[.strikethroughColor] = fontColor.withAlphaComponent(0.3)
			} else {
				labelAttributes[.strikethroughColor] = fontColor
			}
		} else {
			labelAttributes[.strikethroughStyle] = 0
		}
		
		labelAttributes[.font] = OutlineFontCache.shared.numberingFont(level: row.trueLevel)

		attrString.setAttributes(labelAttributes, range: NSRange(location: 0, length: attrString.length))
		
		attributedText = attrString
	}
	
}
