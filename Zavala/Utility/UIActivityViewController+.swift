//
//  UIActivityViewController+.swift
//  Zavala
//
//  Created by Maurice Parker on 2/28/21.
//

import UIKit
import Templeton

extension UIActivityViewController {
	convenience init(outline: Outline, applicationActivities: [UIActivity]? = nil) {
		let outlineItemSource = OutlineActivityItemSource(outline: outline)
		self.init(activityItems: [outlineItemSource], applicationActivities: applicationActivities)
	}
}
