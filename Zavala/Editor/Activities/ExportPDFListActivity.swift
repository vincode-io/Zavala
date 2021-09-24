//
//  ExportPDFListActivity.swift
//  Zavala
//
//  Created by Maurice Parker on 9/24/21.
//

import UIKit

protocol ExportPDFListActivityDelegate: AnyObject {
	func exportPDFList(_ : ExportPDFListActivity)
}

class ExportPDFListActivity: UIActivity {
	
	weak var delegate: ExportPDFListActivityDelegate?
	
	override var activityTitle: String? {
		L10n.exportPDFListEllipsis
	}
	
	override var activityType: UIActivity.ActivityType? {
		UIActivity.ActivityType(rawValue: "io.vincode.Zavala.exportPDFList")
	}
	
	override var activityImage: UIImage? {
		AppAssets.export.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
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
		delegate?.exportPDFList(self)
		activityDidFinish(true)
	}
	
}
