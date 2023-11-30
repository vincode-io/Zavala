//
//  CopyDocumentLinkActivity.swift
//  Zavala
//
//  Created by Maurice Parker on 11/16/22.
//

import UIKit
import VinOutlineKit

class CopyDocumentLinkActivity: UIActivity {
	
	private let documents: [Document]
	
	init(documents: [Document]) {
		self.documents = documents
	}
	
	override var activityTitle: String? {
		if documents.count > 1 {
			return AppStringAssets.copyDocumentLinksControlLabel
		} else {
			return AppStringAssets.copyDocumentLinkControlLabel
		}
	}
	
	override var activityType: UIActivity.ActivityType? {
		UIActivity.ActivityType(rawValue: "io.vincode.Zavala.copyDocumentLink")
	}
	
	override var activityImage: UIImage? {
		ZavalaImageAssets.link
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
		UIPasteboard.general.strings = documents.compactMap { $0.id.url?.absoluteString }
		activityDidFinish(true)
	}
}
