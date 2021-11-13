//
//  NSActivity+.swift
//  Zavala
//
//  Created by Maurice Parker on 3/18/21.
//

import Foundation

extension NSUserActivity {
	struct ActivityType {
		static let newWindow = "io.vincode.Zavala.newWindow"
		static let openEditor = "io.vincode.Zavala.openEditor"
		static let newOutline = "io.vincode.Zavala.newOutline"
		static let openQuickly = "io.vincode.Zavala.openQuickly"
		static let viewImage = "io.vincode.Zavala.viewImage"

		static let restoration = "io.vincode.Zavala.restoration"
		static let selectingDocumentContainer = "io.vincode.Zavala.selectingDocumentContainer"
		static let selectingDocument = "io.vincode.Zavala.selectingDocument"
	}
}
