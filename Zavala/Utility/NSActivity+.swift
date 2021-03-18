//
//  NSActivity+.swift
//  Zavala
//
//  Created by Maurice Parker on 3/18/21.
//

import Foundation

extension NSUserActivity {
	enum ActivityType: String {
		case newWindow = "io.vincode.Zavala.newWindow"
		case openEditor = "io.vincode.Zavala.openEditor"
		case restoration = "io.vincode.Zavala.restoration"
		case selectingDocumentContainer = "io.vincode.Zavala.selectingDocumentContainer"
		case selectingDocument = "io.vincode.Zavala.selectingDocument"
	}
}
