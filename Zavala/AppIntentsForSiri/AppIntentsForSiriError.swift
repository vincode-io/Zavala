//
//  AppIntentsForSiriError.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation

enum AppIntentsForSiriError: Error, CustomLocalizedStringResourceConvertible {
	case folderNotFound
	case folderInDifferentAccount

	var localizedStringResource: LocalizedStringResource {
		switch self {
		case .folderNotFound:
			return LocalizedStringResource("label.text.intent-error-folder-not-found", comment: "Error text: The requested Tag was not found.")
		case .folderInDifferentAccount:
			return LocalizedStringResource("label.text.intent-error-folder-in-different-account", comment: "Error text: The Tag is in a different Account than the Outline.")
		}
	}
}
