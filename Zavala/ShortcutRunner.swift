//
//  ShortcutRunner.swift
//  Zavala
//
//  Created by Maurice Parker on 3/3/26.
//

import UIKit
import OSLog

enum ShortcutRunnerError: LocalizedError {
	case shortcutNotFound(String)
	case shortcutCancelled(String)
	case shortcutError(String, String)
	case unableToOpenShortcutsApp

	var errorDescription: String? {
		switch self {
		case .shortcutNotFound(let name):
			return String(localized: "The shortcut \"\(name)\" was not found.")
		case .shortcutCancelled(let name):
			return String(localized: "The shortcut \"\(name)\" was cancelled.")
		case .shortcutError(let name, let message):
			return String(localized: "The shortcut \"\(name)\" returned an error: \(message)")
		case .unableToOpenShortcutsApp:
			return String(localized: "Unable to open the Shortcuts app.")
		}
	}
}

@MainActor
final class ShortcutRunner {

	let defaultShortcutName = "Create an Outline with AI"
	let defaultShortcutURL = URL(string: "https://zavala.vincode.io/assets/shortcuts/Create%20an%20Outline%20with%20AI.shortcut")!

	private static let callbackScheme = "zavala"
	private static let shortcutsScheme = "shortcuts"
	private var currentShortcutName: String?
	private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ShortcutRunner")

	init() {
		let initialized = AppDefaults.shared.initialShortcutsMenuSetup
		let shortcutsMenu = AppDefaults.shared.shortcutsMenuEntries
		if !initialized && shortcutsMenu.isEmpty {
			AppDefaults.shared.shortcutsMenuEntries = [defaultShortcutName]
			AppDefaults.shared.initialShortcutsMenuSetup = true
		}
	}

	func runShortcut(named shortcutName: String) {
		currentShortcutName = shortcutName

		guard let encodedName = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }

		let xSuccess = "\(Self.callbackScheme)://x-callback-url/shortcut-success"
		let xCancel = "\(Self.callbackScheme)://x-callback-url/shortcut-cancel"
		let xError = "\(Self.callbackScheme)://x-callback-url/shortcut-error"

		guard let encodedSuccess = xSuccess.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
			  let encodedCancel = xCancel.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
			  let encodedError = xError.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }

		let urlString = "\(Self.shortcutsScheme)://x-callback-url/run-shortcut?name=\(encodedName)&x-success=\(encodedSuccess)&x-cancel=\(encodedCancel)&x-error=\(encodedError)"

		guard let url = URL(string: urlString) else { return }

		UIApplication.shared.open(url, options: [:]) { success in
			if !success {
				appDelegate.presentError(ShortcutRunnerError.unableToOpenShortcutsApp, title: .shortcutErrorTitle)
			}
		}
	}

	func handleCallbackURL(_ url: URL) {
		guard url.scheme == Self.callbackScheme,
			  url.host == "x-callback-url" else { return }

		let path = url.path
		let shortcutName = currentShortcutName ?? ""
		currentShortcutName = nil

		switch path {
		case "/shortcut-success":
			logger.info("Shortcut \"\(shortcutName)\" completed successfully.")
		case "/shortcut-cancel":
			logger.info("Shortcut \"\(shortcutName)\" was cancelled.")
			appDelegate.presentError(ShortcutRunnerError.shortcutCancelled(shortcutName), title: .shortcutErrorTitle)
		case "/shortcut-error":
			let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
			let errorMessage = components?.queryItems?.first(where: { $0.name == "errorMessage" })?.value ?? .unknownLabel
			logger.error("Shortcut \"\(shortcutName)\" failed with error: \(errorMessage)")
			if shortcutName == defaultShortcutName {
				promptToDownloadDefaultShortcut()
			} else {
				appDelegate.presentError(ShortcutRunnerError.shortcutError(shortcutName, errorMessage), title: .shortcutErrorTitle)
			}
		default:
			break
		}
	}

	// MARK: Helpers

	private func promptToDownloadDefaultShortcut() {
		let title = String.downloadShortcutTitle
		let message = String.downloadShortcutMessage

		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

		let downloadAction = UIAlertAction(title: .downloadControlLabel, style: .default) { [weak self] _ in
			self?.importDefaultShortcut()
		}
		alertController.addAction(downloadAction)

		let cancelAction = UIAlertAction(title: .cancelControlLabel, style: .cancel)
		alertController.addAction(cancelAction)

		alertController.preferredAction = downloadAction

		appDelegate.mainCoordinator?.present(alertController, animated: true)
	}

	private func importDefaultShortcut() {
		UIApplication.shared.open(defaultShortcutURL, options: [:]) { success in
			if !success {
				appDelegate.presentError(ShortcutRunnerError.unableToOpenShortcutsApp, title: .shortcutErrorTitle)
			}
		}
	}

}
