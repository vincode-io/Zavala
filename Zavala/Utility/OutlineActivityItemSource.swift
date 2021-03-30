//
//  OutlineActivityItemSource.swift
//  Zavala
//
//  Created by Maurice Parker on 2/28/21.
//

import UIKit
import Templeton

class OutlineActivityItemSource: NSObject, UIActivityItemSource {
	
	private let outline: Outline
	
	init(outline: Outline) {
		self.outline = outline
	}
	
	func activityViewControllerPlaceholderItem(_ : UIActivityViewController) -> Any {
		return outline.markdownOutline()
	}
	
	func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
		return outline.markdownOutline()
	}
	
	func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
		return outline.title ?? ""
	}
	
}
