//
//  MetadataTextAttachment.swift
//  
//
//  Created by Maurice Parker on 10/27/21.
//

import UIKit

public class MetadataTextAttachment: NSTextAttachment {
	
	public var view: UIView?
	
	private var font: UIFont {
		let bodyFont = UIFont.preferredFont(forTextStyle: .body)
		return bodyFont.withSize(bodyFont.pointSize - 1.0)
	}
	
	public override init(data contentData: Data?, ofType uti: String?) {
		super.init(data: contentData, ofType: uti)
		
		let button = UIButton()
		
		button.titleLabel?.font = font
		button.backgroundColor = .systemGray4
		button.setTitleColor(.secondaryLabel, for: .normal)
		button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
		button.layer.cornerRadius = 4 // button.intrinsicContentSize.height / 2
		button.setTitle("Test", for: .normal)
		view = button
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
		guard let view = view else {
			return attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
		}
		
		let size = view.sizeThatFits(.zero)
		return CGRect(x: 0, y:-2, width: size.width, height: font.capHeight + 4.0)
	}
	
}
