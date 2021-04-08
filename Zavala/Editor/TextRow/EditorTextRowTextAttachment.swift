//
//  EditorTextRowTextAttachment.swift
//  Zavala
//
//  Created by Maurice Parker on 4/6/21.
//

import UIKit

class EditorTextRowTextAttachment: NSTextAttachment {
	
	override init(data contentData: Data?, ofType uti: String?) {
		super.init(data: contentData, ofType: uti)
		if image == nil, let contentData = contentData {
			image = UIImage(data: contentData)
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
		guard let image = image else {
			return super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
		}
		
		let width = lineFrag.size.width
		let imageSize = image.size
		
		var scalingFactor: CGFloat = 1.0
		if width < imageSize.width {
			scalingFactor = width / imageSize.width
		}

		return CGRect(x: 0, y: 0, width: imageSize.width * scalingFactor, height: imageSize.height * scalingFactor)
	}
	
}
