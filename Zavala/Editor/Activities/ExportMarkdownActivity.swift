//
//  ExportMarkdownActivity.swift
//  Zavala
//
//  Created by Maurice Parker on 3/30/21.
//

import UIKit

protocol ExportMarkdownActivityDelegate: AnyObject {
	func exportMarkdown(_ : ExportMarkdownActivity)
}

class ExportMarkdownActivity: UIActivity {
	
	weak var delegate: ExportMarkdownActivityDelegate?
	
	override var activityTitle: String? {
		L10n.exportMarkdown
	}
	
	override var activityType: UIActivity.ActivityType? {
		UIActivity.ActivityType(rawValue: "io.vincode.Zavala.exportMarkdown")
	}
	
	override var activityImage: UIImage? {
		AppAssets.exportMarkdownOutline.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
	}
	
	override class var activityCategory: UIActivity.Category {
		.action
	}
	
	override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
		true
	}
	
	override func prepare(withActivityItems activityItems: [Any]) {
		
	}
	
	override func perform() {
		delegate?.exportMarkdown(self)
		activityDidFinish(true)
	}
	
}
