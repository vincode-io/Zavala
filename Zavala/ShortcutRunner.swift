//
//  ShortcutRunner.swift
//  Zavala
//
//  Created by Maurice Parker on 3/3/26.
//

struct ShortcutRunner {

	private let defaultShortcutName = "Create an Outline with AI"
	private let defaultShortcutURL = URL(string: "https://zavala.vincode.io/assets/shortcuts/Create_an_Outline_with_AI.shortcut")!

	init () {
		let initialized = AppDefaults.shared.initialShortcutsMenuSetup
		let shortcutsMenu = AppDefaults.shared.shortcutsMenuEntries
		if !initialized && shortcutsMenu.isEmpty {
			AppDefaults.shared.shortcutsMenuEntries = [defaultShortcutName]
			AppDefaults.shared.initialShortcutsMenuSetup = true
		}
	}

	func runShortcut(named shortcutName: String) throws {
		print("******* \(shortcutName)")
	}

}
