//
//  Created by Maurice Parker on 9/3/24.
//

import UIKit

final class EditorRowHighlightLayoutFragment: NSTextLayoutFragment {
	
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
				if attributes[.codeInline] as? Bool == true {
					highlight(lineFragment: lineFragment, range: range, color: UIColor.secondarySystemFill.cgColor, in: ctx)
				}
			}
		}

		super.draw(at: renderingOrigin, in: ctx)

		// Dim highlight-formatted runs in a completed Topic to the same degree as the surrounding text.
		// The native highlight style draws at full opacity, so we lower the opacity of the drawn pixels
		// after the fact. Since the text view background is clear, this reveals the row background behind
		// the highlight and composites it down to match the dimmed text.
		for lineFragment in textLineFragments {
			lineFragment.attributedString.enumerateAttribute(.dimmedHighlight, in: lineFragment.characterRange, options: []) { (value, range, _) in
				if value as? Bool == true {
					dim(lineFragment: lineFragment, range: range, in: ctx)
				}
			}
		}
	}
}

private extension EditorRowHighlightLayoutFragment {
	
	private func highlight(lineFragment: NSTextLineFragment, range: NSRange, color: CGColor, in ctx: CGContext) {
		var lineFragmentBounds = lineFragment.typographicBounds
		let lowerBound = lineFragment.locationForCharacter(at: range.lowerBound).x
		let upperBound = lineFragment.locationForCharacter(at: range.upperBound).x
		
		lineFragmentBounds.origin.x = lowerBound
		lineFragmentBounds.size.width = upperBound - lowerBound
		
		let drawingPath = lineFragmentBounds.insetBy(dx: -1, dy: 0)

		ctx.saveGState()
		
		ctx.addPath(CGPath(roundedRect: drawingPath, cornerWidth: 3, cornerHeight: 3, transform: nil))
		ctx.setFillColor(color)
		ctx.fillPath()

		ctx.restoreGState()
	}

	// The `0.3` foreground alpha used to dim completed Topic text; matching it here keeps the highlight
	// consistent with the surrounding dimmed text.
	static let dimmedAlpha = 0.3

	private func dim(lineFragment: NSTextLineFragment, range: NSRange, in ctx: CGContext) {
		var lineFragmentBounds = lineFragment.typographicBounds
		let lowerBound = lineFragment.locationForCharacter(at: range.lowerBound).x
		let upperBound = lineFragment.locationForCharacter(at: range.upperBound).x

		lineFragmentBounds.origin.x = lowerBound
		lineFragmentBounds.size.width = upperBound - lowerBound

		let drawingPath = lineFragmentBounds.insetBy(dx: -1, dy: 0)

		ctx.saveGState()

		// `destinationOut` scales the alpha of what's already drawn by `(1 - fill alpha)`, so filling with
		// `1 - dimmedAlpha` leaves the highlight at `dimmedAlpha` opacity.
		ctx.setBlendMode(.destinationOut)
		ctx.addPath(CGPath(roundedRect: drawingPath, cornerWidth: 3, cornerHeight: 3, transform: nil))
		ctx.setFillColor(gray: 0, alpha: 1 - Self.dimmedAlpha)
		ctx.fillPath()

		ctx.restoreGState()
	}

}
