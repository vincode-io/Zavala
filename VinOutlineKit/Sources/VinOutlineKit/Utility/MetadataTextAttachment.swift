//
//  MetadataTextAttachment.swift
//  
//
//  Created by Maurice Parker on 10/27/21.
//

#if canImport(UIKit)

import UIKit

public class MetadataTextAttachment: NSTextAttachment {
	
	public private(set) var view: UIView!
	
	private var adjustedBounds: CGRect!
	
	public override init(data contentData: Data?, ofType uti: String?) {
		super.init(data: contentData, ofType: uti)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func configure(key: String, value: String, level: Int) {
		view = MetadataViewManager.provider.provide(key: key, value: value, level: level)
		let bounds = view.bounds
		// TODO: fix this temporary hack for the y coordinate
		adjustedBounds = CGRect(x: 0, y: -(bounds.height / 8), width: bounds.width, height: bounds.height)
	}
	
	public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
		return adjustedBounds
	}
	
}

#endif
