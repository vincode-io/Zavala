//
//  PrintActivity.swift
//  Zavala
//
//  Created by Maurice Parker on 3/30/21.
//

import UIKit

protocol PrintActivityDelegate: AnyObject {
	func print(_ : PrintActivity)
}

class PrintActivity: UIActivity {
	
	weak var delegate: PrintActivityDelegate?
	
	override var activityTitle: String? {
		L10n.print
	}
	
	override var activityType: UIActivity.ActivityType? {
		UIActivity.ActivityType(rawValue: "io.vincode.Zavala.print")
	}
	
	override var activityImage: UIImage? {
		AppAssets.print.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
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
		delegate?.print(self)
		activityDidFinish(true)
	}
	
}
