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
	
	@objc func deleteEntityCommand(_ sender: Any?) {
		mainSplitViewController?.deleteEntity(sender)
	}
	
	@objc func toggleOutlineIsFavoriteCommand(_ sender: Any?) {
		mainSplitViewController?.toggleOutlineIsFavorite(sender)
	}
	
	@objc func toggleSidebarCommand(_ sender: Any?) {
		mainSplitViewController?.toggleSidebar(sender)
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
		case #selector(deleteEntityCommand(_:)):
			if mainSplitViewController?.isDeleteEntityUnavailable ?? true {
				command.attributes = .disabled
			}
		default:
			break
		}
	}
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		if action == #selector(deleteEntityCommand(_:)) {
			return !UIResponder.isFirstResponderTextField
		}
		return super.canPerformAction(action, withSender: sender)
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

		// Standard Edit Menu (Use backspace to trigger delete key)
		builder.replaceChildren(ofMenu: .standardEdit) { oldElements in
			var newElements = [UIMenuElement]()
			for oldElement in oldElements {
				if oldElement.title == "Delete" {
					let delete = UIKeyCommand(title: oldElement.title, action: #selector(deleteEntityCommand(_:)), input: "\u{8}", modifierFlags: [])
					newElements.append(delete)
				} else {
					newElements.append(oldElement)
				}
			}
			return newElements
		}
		
		// View Menu
		let toggleSidebarMenu = UIMenu(title: "", options: .displayInline, children: [toggleSidebarCommand])
		builder.insertSibling(toggleSidebarMenu, afterMenu: .toolbar)
	}
	
}

