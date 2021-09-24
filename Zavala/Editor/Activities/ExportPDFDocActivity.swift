//
//  ExportPDFDocActivity.swift
//  Zavala
//
//  Created by Maurice Parker on 9/24/21.
//

import UIKit

protocol ExportPDFDocActivityDelegate: AnyObject {
	func exportPDFDoc(_ : ExportPDFDocActivity)
}

class ExportPDFDocActivity: UIActivity {
	
	weak var delegate: ExportPDFDocActivityDelegate?
	
	override var activityTitle: String? {
		L10n.exportPDFDocEllipsis
	}
	
	override var activityType: UIActivity.ActivityType? {
		UIActivity.ActivityType(rawValue: "io.vincode.Zavala.exportPDFDOc")
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
		delegate?.exportPDFDoc(self)
		activityDidFinish(true)
	}
	
}
