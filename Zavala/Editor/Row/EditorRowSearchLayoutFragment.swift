//
//  Created by Maurice Parker on 9/3/24.
//

import UIKit

final class EditorRowSearchLayoutFragment: NSTextLayoutFragment {
	
	override init(textElement: NSTextElement, range rangeInElement: NSTextRange?) {
		super.init(textElement: textElement, range: rangeInElement)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func draw(at renderingOrigin: CGPoint, in ctx: CGContext) {
		for lineFragment in textLineFragments {
			lineFragment.attributedString.enumerateAttributes(in: lineFragment.characterRange, options: []) { (attributes, range, _) in
				if attributes[.selectedSearchResult] as? Bool == true {
					highlight(lineFragment: lineFragment, range: range, color: UIColor.systemYellow.cgColor, in: ctx)
				}
				if attributes[.searchResult] as? Bool == true {
					highlight(lineFragment: lineFragment, range: range, color: UIColor.systemGray.cgColor, in: ctx)
				}
			}
		}
		
		super.draw(at: renderingOrigin, in: ctx)
	}
}

private extension EditorRowSearchLayoutFragment {
	
	private func highlight(lineFragment: NSTextLineFragment, range: NSRange, color: CGColor, in ctx: CGContext) {
		var lineFragmentBounds = lineFragment.typographicBounds
		let lowerBound = lineFragment.locationForCharacter(at: range.lowerBound).x
		let upperBound = lineFragment.locationForCharacter(at: range.upperBound).x
		
		lineFragmentBounds.origin.x = lowerBound
		lineFragmentBounds.size.width = upperBound - lowerBound
		
		let drawingPath = lineFragmentBounds.insetBy(dx: -2, dy: -2)

		ctx.saveGState()
		
		ctx.addPath(CGPath(roundedRect: drawingPath, cornerWidth: 3, cornerHeight: 3, transform: nil))
		ctx.setFillColor(color)
		ctx.fillPath()

		ctx.restoreGState()
	}
	
}
