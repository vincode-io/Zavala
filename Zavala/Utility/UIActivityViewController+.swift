//
//  UIActivityViewController+.swift
//  Zavala
//
//  Created by Maurice Parker on 2/28/21.
//

import UIKit
import Templeton

extension UIActivityViewController {
	
	convenience init(documents: [Document]) {
		let outlineItemSources = documents.compactMap({ $0.outline }).map( { OutlineActivityItemSource(outline: $0) } )
		let copyDocumentLinkActivity = CopyDocumentLinkActivity(documents: documents)
		self.init(activityItems: outlineItemSources, applicationActivities: [copyDocumentLinkActivity])
	}
	
}
