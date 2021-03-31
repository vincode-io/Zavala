//
//  ExportOPMLActivity.swift
//  Zavala
//
//  Created by Maurice Parker on 3/30/21.
//

import UIKit

protocol ExportOPMLActivityDelegate: AnyObject {
	func exportOPML(_ : ExportOPMLActivity)
}

class ExportOPMLActivity: UIActivity {
	
	weak var delegate: ExportOPMLActivityDelegate?
	
	override var activityTitle: String? {
		L10n.exportOPML
	}
	
	override var activityType: UIActivity.ActivityType? {
		UIActivity.ActivityType(rawValue: "io.vincode.Zavala.exportOPML")
	}
	
	override var activityImage: UIImage? {
		AppAssets.exportOPML.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
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
		delegate?.exportOPML(self)
		activityDidFinish(true)
	}
	
}
