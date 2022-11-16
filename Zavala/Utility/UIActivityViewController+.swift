//
//  UIActivityViewController+.swift
//  Zavala
//
//  Created by Maurice Parker on 2/28/21.
//

import UIKit
import Templeton

extension UIActivityViewController {
	
	convenience init(outline: Outline) {
		let outlineItemSource = OutlineActivityItemSource(outline: outline)
		let copyDocumentLinkActivity = CopyDocumentLinkActivity(documents: [Document.outline(outline)])
		self.init(activityItems: [outlineItemSource], applicationActivities: [copyDocumentLinkActivity])
	}
	
}
