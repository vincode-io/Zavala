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
			return String.shortcutNotFound(name: name)
		case .shortcutCancelled(let name):
			return String.shortcutCancelled(name: name)
		case .shortcutError(let name, let message):
			return String.shortcutError(name: name, message: message)
		case .unableToOpenShortcutsApp:
			return String.unableToOpenShortcutsAppLabel
		}
	}
}

@MainActor
final class ShortcutRunner {

	private static let callbackScheme = "zavala"
	private static let shortcutsScheme = "shortcuts"
	private var currentShortcutName: String?

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
		case "/shortcut-cancel":
			appDelegate.presentError(ShortcutRunnerError.shortcutCancelled(shortcutName), title: .shortcutErrorTitle)
		case "/shortcut-error":
			let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
			let errorMessage = components?.queryItems?.first(where: { $0.name == "errorMessage" })?.value ?? .unknownLabel
			appDelegate.presentError(ShortcutRunnerError.shortcutError(shortcutName, errorMessage), title: .shortcutErrorTitle)
		default:
			break
		}
	}

}
