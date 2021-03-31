//
//  ExportPostActivity.swift
//  Zavala
//
//  Created by Maurice Parker on 3/30/21.
//

import UIKit

protocol ExportPostActivityDelegate: AnyObject {
	func exportPost(_ : ExportPostActivity)
}

class ExportPostActivity: UIActivity {
	
	weak var delegate: ExportPostActivityDelegate?
	
	override var activityTitle: String? {
		L10n.exportMarkdownPost
	}
	
	override var activityType: UIActivity.ActivityType? {
		UIActivity.ActivityType(rawValue: "io.vincode.Zavala.exportPost")
	}
	
	override var activityImage: UIImage? {
		AppAssets.exportMarkdownPost.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
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
		delegate?.exportPost(self)
		activityDidFinish(true)
	}
	
}
