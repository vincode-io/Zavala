//
//  ExportMarkdownDocActivity.swift
//  Zavala
//
//  Created by Maurice Parker on 9/21/21.
//

import UIKit

protocol ExportMarkdownDocActivityDelegate: AnyObject {
	func exportMarkdownDoc(_ : ExportMarkdownDocActivity)
}

class ExportMarkdownDocActivity: UIActivity {
	
	weak var delegate: ExportMarkdownDocActivityDelegate?
	
	override var activityTitle: String? {
		L10n.exportMarkdownDoc
	}
	
	override var activityType: UIActivity.ActivityType? {
		UIActivity.ActivityType(rawValue: "io.vincode.Zavala.exportMarkdownDoc")
	}
	
	override var activityImage: UIImage? {
		AppAssets.exportMarkdownDoc.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
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
		delegate?.exportMarkdownDoc(self)
		activityDidFinish(true)
	}
	
}
