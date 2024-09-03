//
//  ImageTextAttachment.swift
//  Zavala
//
//  Created by Maurice Parker on 4/6/21.
//

#if canImport(UIKit)
import UIKit

public class ImageTextAttachment: NSTextAttachment {
	
	public override class var supportsSecureCoding: Bool { return true }
	
	public var imageUUID: String? = nil

	public override init(data contentData: Data?, ofType uti: String?) {
		super.init(data: contentData, ofType: uti)
		if image == nil, let contentData {
			image = UIImage(data: contentData)
		}
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		imageUUID = coder.decodeObject(forKey: "imageUUID") as? String
	}
	
	public override func encode(with coder: NSCoder) {
		coder.encode(imageUUID, forKey: "imageUUID")
		super.encode(with: coder)
	}
	
	public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
		guard let image else {
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
#endif
