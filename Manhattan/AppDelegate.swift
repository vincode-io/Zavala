//
//  AppDelegate.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import Templeton

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	override var keyCommands: [UIKeyCommand]? {
		#if targetEnvironment(macCatalyst)
		return nil
		#else
		var menuKeyCommands = [UIKeyCommand]()
		
		if !(mainSplitViewController?.isCreateOutlineUnavailable ?? true) {
			menuKeyCommands.append(newOutlineCommand)
			menuKeyCommands.append(importOPMLCommand)
		}
		
		if !(mainSplitViewController?.isCreateFolderUnavailable ?? true) {
			menuKeyCommands.append(newFolderCommand)
		}
		
		if !(mainSplitViewController?.isExportOutlineUnavailable ?? true) {
			menuKeyCommands.append(exportMarkdownCommand)
			menuKeyCommands.append(exportOPMLCommand)
		}
		
		menuKeyCommands.append(newWindowCommand)
		menuKeyCommands.append(toggleSidebarCommand)
		
		if !(mainSplitViewController?.isCreateHeadlineUnavailable ?? true) {
			menuKeyCommands.append(createHeadlineCommand)
		}
		
		if !(mainSplitViewController?.isIndentHeadlineUnavailable ?? true) {
			menuKeyCommands.append(indentHeadlineCommand)
		}
		
		if !(mainSplitViewController?.isOutdentHeadlineUnavailable ?? true) {
			menuKeyCommands.append(outdentHeadlineCommand)
		}
		
		if !(mainSplitViewController?.isToggleHeadlineCompleteUnavailable ?? true) {
			if mainSplitViewController?.isCurrentHeadlineComplete ?? false {
				menuKeyCommands.append(uncompleteHeadlineCommand)
			} else {
				menuKeyCommands.append(completeHeadlineCommand)
			}
		}
		
		return menuKeyCommands
		#endif
	}
	
	let exportOPMLCommand = UIKeyCommand(title: L10n.exportOPML,
										action: #selector(exportOPMLCommand(_:)),
										input: "e",
										modifierFlags: [.shift, .command])
	
	let exportMarkdownCommand = UIKeyCommand(title: L10n.exportMarkdown,
											 action: #selector(exportMarkdownCommand(_:)),
											 input: "e",
											 modifierFlags: [.control, .command])
	
	let importOPMLCommand = UIKeyCommand(title: L10n.importOPML,
										action: #selector(importOPMLCommand(_:)),
										input: "i",
										modifierFlags: [.shift, .command])
	
	let newWindowCommand = UIKeyCommand(title: L10n.newWindow,
										action: #selector(newWindow(_:)),
										input: "n",
										modifierFlags: [.alternate, .command])
	
	let newOutlineCommand = UIKeyCommand(title: L10n.newOutline,
										action: #selector(createOutlineCommand(_:)),
										input: "n",
										modifierFlags: [.command])
	
	let newFolderCommand = UIKeyCommand(title: L10n.newFolder,
										action: #selector(createFolderCommand(_:)),
										input: "n",
										modifierFlags: [.shift, .command])
	
	let toggleSidebarCommand = UIKeyCommand(title: L10n.toggleSidebar,
										action: #selector(toggleSidebarCommand(_:)),
										input: "s",
										modifierFlags: [.control, .command])

	let createHeadlineCommand = UIKeyCommand(title: L10n.addRow,
										action: #selector(createHeadlineCommand(_:)),
										input: "\n",
										modifierFlags: [])

	let indentHeadlineCommand = UIKeyCommand(title: L10n.indent,
										action: #selector(indentHeadlineCommand(_:)),
										input: "]",
										modifierFlags: [.command])

	let outdentHeadlineCommand = UIKeyCommand(title: L10n.outdent,
										action: #selector(outdentHeadlineCommand(_:)),
										input: "[",
										modifierFlags: [.command])

	let toggleCompleteHeadlineCommand = UIKeyCommand(title: L10n.complete,
										action: #selector(toggleCompleteHeadlineCommand(_:)),
										input: "\n",
										modifierFlags: [.command])

	let completeHeadlineCommand = UIKeyCommand(title: L10n.complete,
										action: #selector(toggleCompleteHeadlineCommand(_:)),
										input: "\n",
										modifierFlags: [.command])

	let uncompleteHeadlineCommand = UIKeyCommand(title: L10n.uncomplete,
										action: #selector(toggleCompleteHeadlineCommand(_:)),
										input: "\n",
										modifierFlags: [.command])

	let splitHeadlineCommand = UIKeyCommand(title: L10n.splitRow,
										action: #selector(splitHeadlineCommand(_:)),
										input: "\n",
										modifierFlags: [.shift, .alternate])

	var mainSplitViewController: MainSplitViewController? {
		var keyScene: UIScene?
		let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
		
		for windowScene in windowScenes {
			if !windowScene.windows.filter({ $0.isKeyWindow }).isEmpty {
				keyScene = windowScene
			}
		}
		
		return (keyScene?.delegate as? SceneDelegate)?.mainSplitViewController
	}

	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		let documentAccountURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let documentAccountsFolder = documentAccountURL.appendingPathComponent("Accounts").absoluteString
		let documentAccountsFolderPath = String(documentAccountsFolder.suffix(from: documentAccountsFolder.index(documentAccountsFolder.startIndex, offsetBy: 7)))
		AccountManager.shared = AccountManager(accountsFolderPath: documentAccountsFolderPath)
		return true
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		AppDefaults.registerDefaults()
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	// MARK: Actions

	@objc func importOPMLCommand(_ sender: Any?) {
		mainSplitViewController?.importOPML(sender)
	}

	@objc func exportMarkdownCommand(_ sender: Any?) {
		mainSplitViewController?.exportMarkdown(sender)
	}

	@objc func exportOPMLCommand(_ sender: Any?) {
		mainSplitViewController?.exportOPML(sender)
	}

	@objc func newWindow(_ sender: Any?) {
		let userActivity = NSUserActivity(activityType: "io.vincode.Manhattan.create")
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil, errorHandler: nil)
	}
	
	@objc func createFolderCommand(_ sender: Any?) {
		mainSplitViewController?.createFolder(sender)
	}
	
	@objc func createOutlineCommand(_ sender: Any?) {
		mainSplitViewController?.createOutline(sender)
	}
	
	@objc func toggleOutlineIsFavoriteCommand(_ sender: Any?) {
		mainSplitViewController?.toggleOutlineIsFavorite(sender)
	}
	
	@objc func toggleSidebarCommand(_ sender: Any?) {
		mainSplitViewController?.toggleSidebar(sender)
	}
	
	@objc func createHeadlineCommand(_ sender: Any?) {
		mainSplitViewController?.createHeadline(sender)
	}
	
	@objc func indentHeadlineCommand(_ sender: Any?) {
		mainSplitViewController?.indentHeadline(sender)
	}
	
	@objc func outdentHeadlineCommand(_ sender: Any?) {
		mainSplitViewController?.outdentHeadline(sender)
	}
	
	@objc func toggleCompleteHeadlineCommand(_ sender: Any?) {
		mainSplitViewController?.toggleCompleteHeadline(sender)
	}
	
	@objc func splitHeadlineCommand(_ sender: Any?) {
		mainSplitViewController?.splitHeadline(sender)
	}
	
	// MARK: Validations
	
	override func validate(_ command: UICommand) {
		switch command.action {
		case #selector(exportMarkdownCommand(_:)), #selector(exportOPMLCommand(_:)):
			if mainSplitViewController?.isExportOutlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(createFolderCommand(_:)):
			if mainSplitViewController?.isCreateFolderUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(createOutlineCommand(_:)), #selector(importOPMLCommand(_:)):
			if mainSplitViewController?.isCreateOutlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(createHeadlineCommand(_:)):
			if mainSplitViewController?.isCreateHeadlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(indentHeadlineCommand(_:)):
			if mainSplitViewController?.isIndentHeadlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(outdentHeadlineCommand(_:)):
			if mainSplitViewController?.isOutdentHeadlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(toggleCompleteHeadlineCommand(_:)):
			if mainSplitViewController?.isCurrentHeadlineComplete ?? false {
				command.title = L10n.uncomplete
			} else {
				command.title = L10n.complete
			}
			if mainSplitViewController?.isToggleHeadlineCompleteUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(splitHeadlineCommand(_:)):
			if mainSplitViewController?.isSplitHeadlineUnavailable ?? true {
				command.attributes = .disabled
			}
		default:
			break
		}
	}
		
	// MARK: Menu

	override func buildMenu(with builder: UIMenuBuilder) {
		super.buildMenu(with: builder)
		guard builder.system == UIMenuSystem.main else { return }
		
		builder.remove(menu: .newScene)

		// File Menu
		let importExportMenu = UIMenu(title: "", options: .displayInline, children: [importOPMLCommand, exportMarkdownCommand, exportOPMLCommand])
		builder.insertChild(importExportMenu, atStartOfMenu: .file)

		let newWindowMenu = UIMenu(title: "", options: .displayInline, children: [newWindowCommand])
		builder.insertChild(newWindowMenu, atStartOfMenu: .file)

		let newItemsMenu = UIMenu(title: "", options: .displayInline, children: [newOutlineCommand, newFolderCommand])
		builder.insertChild(newItemsMenu, atStartOfMenu: .file)
		
		// View Menu
		let toggleSidebarMenu = UIMenu(title: "", options: .displayInline, children: [toggleSidebarCommand])
		builder.insertSibling(toggleSidebarMenu, afterMenu: .toolbar)
		
		// Outline Menu
		let completeMenu = UIMenu(title: "", options: .displayInline, children: [toggleCompleteHeadlineCommand])
		let mainOutlineMenu = UIMenu(title: "", options: .displayInline, children: [createHeadlineCommand, splitHeadlineCommand, indentHeadlineCommand, outdentHeadlineCommand])
		let outlineMenu = UIMenu(title: L10n.outline, children: [mainOutlineMenu, completeMenu])
		builder.insertSibling(outlineMenu, afterMenu: .view)

	}
	
}

