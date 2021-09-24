//
//  ExportMarkdownListActivity.swift
//  Zavala
//
//  Created by Maurice Parker on 3/30/21.
//

import UIKit

protocol ExportMarkdownListActivityDelegate: AnyObject {
	func exportMarkdownList(_ : ExportMarkdownListActivity)
}

class ExportMarkdownListActivity: UIActivity {
	
	weak var delegate: ExportMarkdownListActivityDelegate?
	
	override var activityTitle: String? {
		L10n.exportMarkdownListEllipsis
	}
	
	override var activityType: UIActivity.ActivityType? {
		UIActivity.ActivityType(rawValue: "io.vincode.Zavala.exportMarkdownList")
	}
	
	override var activityImage: UIImage? {
		AppAssets.exportMarkdownList.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
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
		delegate?.exportMarkdownList(self)
		activityDidFinish(true)
	}
	
}
