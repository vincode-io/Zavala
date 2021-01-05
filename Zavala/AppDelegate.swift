//
//  AppDelegate.swift
//  Zavala
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
		
		if !(mainSplitViewController?.isOutlineFunctionsUnavailable ?? true) {
			if mainSplitViewController?.isOutlineFiltered ?? false {
				menuKeyCommands.append(showCompletedCommand)
			} else {
				menuKeyCommands.append(hideCompletedCommand)
			}
			if mainSplitViewController?.isOutlineNotesHidden ?? false {
				menuKeyCommands.append(showNotesCommand)
			} else {
				menuKeyCommands.append(hideNotesCommand)
			}
		}
		
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
		
		if !(mainSplitViewController?.isCreateRowUnavailable ?? true) {
			menuKeyCommands.append(createRowCommand)
		}
		
		if !(mainSplitViewController?.isIndentRowsUnavailable ?? true) {
			menuKeyCommands.append(indentRowsCommand)
		}
		
		if !(mainSplitViewController?.isOutdentRowsUnavailable ?? true) {
			menuKeyCommands.append(outdentRowsCommand)
		}
		
		if !(mainSplitViewController?.isToggleRowCompleteUnavailable ?? true) {
			if mainSplitViewController?.isCompleteRowsAvailable ?? false {
				menuKeyCommands.append(completeRowsCommand)
			} else {
				menuKeyCommands.append(uncompleteRowsCommand)
			}
		}
		
		if !(mainSplitViewController?.isCreateRowNotesUnavailable ?? true) {
			menuKeyCommands.append(createRowNotesCommand)
		}

		if !(mainSplitViewController?.isDeleteRowNotesUnavailable ?? true) {
			menuKeyCommands.append(deleteRowNotesCommand)
		}

		if !(mainSplitViewController?.isExpandAllInOutlineUnavailable ?? true) {
			menuKeyCommands.append(expandAllInOutlineCommand)
		}
		
		if !(mainSplitViewController?.isCollapseAllInOutlineUnavailable ?? true) {
			menuKeyCommands.append(collapseAllInOutlineCommand)
		}

		if !(mainSplitViewController?.isExpandAllUnavailable ?? true) {
			menuKeyCommands.append(expandAllCommand)
		}
		
		if !(mainSplitViewController?.isCollapseAllUnavailable ?? true) {
			menuKeyCommands.append(collapseAllCommand)
		}
		
		if !(mainSplitViewController?.isExpandUnavailable ?? true) {
			menuKeyCommands.append(expandCommand)
		}
		
		if !(mainSplitViewController?.isCollapseUnavailable ?? true) {
			menuKeyCommands.append(collapseCommand)
		}

		return menuKeyCommands
		#endif
	}
	
	
	#if targetEnvironment(macCatalyst)
	let checkForUpdates = UIKeyCommand(title: L10n.checkForUpdates,
										 action: #selector(checkForUpdates(_:)),
										 input: ".",
										 modifierFlags: [.command])
	#endif
	
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
	
	let createRowCommand = UIKeyCommand(title: L10n.addRow,
										action: #selector(createRowCommand(_:)),
										input: "\n",
										modifierFlags: [])
	
	let indentRowsCommand = UIKeyCommand(title: L10n.indent,
										 action: #selector(indentRowsCommand(_:)),
										 input: "]",
										 modifierFlags: [.command])
	
	let outdentRowsCommand = UIKeyCommand(title: L10n.outdent,
										  action: #selector(outdentRowsCommand(_:)),
										  input: "[",
										  modifierFlags: [.command])
	
	let toggleCompleteRowsCommand = UIKeyCommand(title: L10n.complete,
												 action: #selector(toggleCompleteRowsCommand(_:)),
												 input: "\n",
												 modifierFlags: [.command])
	
	let completeRowsCommand = UIKeyCommand(title: L10n.complete,
										   action: #selector(toggleCompleteRowsCommand(_:)),
										   input: "\n",
										   modifierFlags: [.command])
	
	let uncompleteRowsCommand = UIKeyCommand(title: L10n.uncomplete,
											 action: #selector(toggleCompleteRowsCommand(_:)),
											 input: "\n",
											 modifierFlags: [.command])
	
	let createRowNotesCommand = UIKeyCommand(title: L10n.addNote,
											 action: #selector(createRowNotesCommand(_:)),
											 input: "\n",
											 modifierFlags: [.shift])
	
	let deleteRowNotesCommand = UIKeyCommand(title: L10n.deleteNote,
											 action: #selector(deleteRowNotesCommand(_:)),
											 input: "\u{8}",
											 modifierFlags: [.shift])
	
	let splitRowCommand = UIKeyCommand(title: L10n.splitRow,
									   action: #selector(splitRowCommand(_:)),
									   input: "\n",
									   modifierFlags: [.shift, .alternate])
	
	let restoreArchiveCommand = UIKeyCommand(title: L10n.restoreArchive,
											 action: #selector(restoreArchiveCommand(_:)),
											 input: "~",
											 modifierFlags: [.control, .command])
	
	let archiveLocalCommand = UIKeyCommand(title: L10n.archiveAccount(AccountType.local.name),
										   action: #selector(archiveLocalCommand(_:)),
										   input: "1",
										   modifierFlags: [.control, .command])
	
	let toggleBoldCommand = UIKeyCommand(title: L10n.bold,
										 action: #selector(toggleBoldCommand(_:)),
										 input: "b",
										 modifierFlags: [.command])
	
	let toggleItalicsCommand = UIKeyCommand(title: L10n.italic,
											action: #selector(toggleItalicsCommand(_:)),
											input: "i",
											modifierFlags: [.command])
	
	let linkCommand = UIKeyCommand(title: L10n.link,
								   action: #selector(linkCommand(_:)),
								   input: "k",
								   modifierFlags: [.command])
	
	let toggleOutlineFilterCommand = UIKeyCommand(title: L10n.hideCompleted,
												  action: #selector(toggleOutlineFilterCommand(_:)),
												  input: "h",
												  modifierFlags: [.shift, .command])
	
	let hideCompletedCommand = UIKeyCommand(title: L10n.hideCompleted,
											action: #selector(toggleOutlineFilterCommand(_:)),
											input: "h",
											modifierFlags: [.shift, .command])
	
	let showCompletedCommand = UIKeyCommand(title: L10n.showCompleted,
											action: #selector(toggleOutlineFilterCommand(_:)),
											input: "h",
											modifierFlags: [.shift, .command])

	let toggleOutlineHideNotesCommand = UIKeyCommand(title: L10n.hideNotes,
												  action: #selector(toggleOutlineHideNotesCommand(_:)),
												  input: "h",
												  modifierFlags: [.shift, .alternate, .command])
	
	let hideNotesCommand = UIKeyCommand(title: L10n.hideNotes,
											action: #selector(toggleOutlineHideNotesCommand(_:)),
											input: "h",
											modifierFlags: [.shift, .alternate, .command])
	
	let showNotesCommand = UIKeyCommand(title: L10n.showNotes,
											action: #selector(toggleOutlineHideNotesCommand(_:)),
											input: "h",
											modifierFlags: [.shift, .alternate, .command])
	
	let expandAllInOutlineCommand = UIKeyCommand(title: L10n.expandAllInOutline,
												 action: #selector(expandAllInOutlineCommand(_:)),
												 input: "9",
												 modifierFlags: [.control, .command])
	
	let collapseAllInOutlineCommand = UIKeyCommand(title: L10n.collapseAllInOutline,
												   action: #selector(collapseAllInOutlineCommand(_:)),
												   input: "0",
												   modifierFlags: [.control, .command])
	
	let expandAllCommand = UIKeyCommand(title: L10n.expandAllInRow,
										action: #selector(expandAllCommand(_:)),
										input: "9",
										modifierFlags: [.alternate, .command])
	
	let collapseAllCommand = UIKeyCommand(title: L10n.collapseAllInRow,
										  action: #selector(collapseAllCommand(_:)),
										  input: "0",
										  modifierFlags: [.alternate, .command])
	
	let expandCommand = UIKeyCommand(title: L10n.expand,
									 action: #selector(expandCommand(_:)),
									 input: "9",
									 modifierFlags: [.command])
	
	let collapseCommand = UIKeyCommand(title: L10n.collapse,
									   action: #selector(collapseCommand(_:)),
									   input: "0",
									   modifierFlags: [.command])
	
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
	
	#if targetEnvironment(macCatalyst)
	var sparklePlugin: SparklePlugin?
	#endif

	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		let documentAccountURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let documentAccountsFolder = documentAccountURL.appendingPathComponent("Accounts").absoluteString
		let documentAccountsFolderPath = String(documentAccountsFolder.suffix(from: documentAccountsFolder.index(documentAccountsFolder.startIndex, offsetBy: 7)))
		AccountManager.shared = AccountManager(accountsFolderPath: documentAccountsFolderPath)
		return true
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		AppDefaults.registerDefaults()

		
		var menuItems = [UIMenuItem]()
		menuItems.append(UIMenuItem(title: L10n.bold, action: .toggleBoldface))
		menuItems.append(UIMenuItem(title: L10n.italic, action: .toggleItalics))
		menuItems.append(UIMenuItem(title: L10n.link, action: .editLink))
		UIMenuController.shared.menuItems = menuItems

		#if targetEnvironment(macCatalyst)
		guard let pluginPath = (Bundle.main.builtInPlugInsPath as NSString?)?.appendingPathComponent("SparklePlugin.bundle"),
			  let bundle = Bundle(path: pluginPath),
			  let cls = bundle.principalClass as? NSObject.Type,
			  let sparklePlugin = cls.init() as? SparklePlugin else { return true }
		
		self.sparklePlugin = sparklePlugin
		sparklePlugin.start()
		#endif
		
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	// MARK: Actions

	#if targetEnvironment(macCatalyst)
	@objc func checkForUpdates(_ sender: Any?) {
		sparklePlugin?.checkForUpdates()
	}
	#endif

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
		let userActivity = NSUserActivity(activityType: "io.vincode.Zavala.create")
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil, errorHandler: nil)
	}
	
	@objc func createFolderCommand(_ sender: Any?) {
		mainSplitViewController?.createFolder(sender)
	}
	
	@objc func createOutlineCommand(_ sender: Any?) {
		mainSplitViewController?.createOutline(sender)
	}
	
	@objc func toggleSidebarCommand(_ sender: Any?) {
		mainSplitViewController?.toggleSidebar(sender)
	}
	
	@objc func createRowCommand(_ sender: Any?) {
		mainSplitViewController?.createRow(sender)
	}
	
	@objc func indentRowsCommand(_ sender: Any?) {
		mainSplitViewController?.indentRows(sender)
	}
	
	@objc func outdentRowsCommand(_ sender: Any?) {
		mainSplitViewController?.outdentRows(sender)
	}
	
	@objc func toggleCompleteRowsCommand(_ sender: Any?) {
		mainSplitViewController?.toggleCompleteRows(sender)
	}
	
	@objc func createRowNotesCommand(_ sender: Any?) {
		mainSplitViewController?.createRowNotes(sender)
	}
	
	@objc func deleteRowNotesCommand(_ sender: Any?) {
		mainSplitViewController?.deleteRowNotes(sender)
	}
	
	@objc func splitRowCommand(_ sender: Any?) {
		mainSplitViewController?.splitRow(sender)
	}
	
	@objc func restoreArchiveCommand(_ sender: Any?) {
		mainSplitViewController?.restoreArchive()
	}
	
	@objc func archiveLocalCommand(_ sender: Any?) {
		mainSplitViewController?.archiveAccount(type: .local)
	}
	
	@objc func toggleBoldCommand(_ sender: Any?) {
		mainSplitViewController?.outlineToggleBoldface(sender)
	}
	
	@objc func toggleItalicsCommand(_ sender: Any?) {
		mainSplitViewController?.outlineToggleItalics(sender)
	}
	
	@objc func linkCommand(_ sender: Any?) {
		mainSplitViewController?.link(sender)
	}

	@objc func toggleOutlineFilterCommand(_ sender: Any?) {
		mainSplitViewController?.toggleOutlineFilter(sender)
	}

	@objc func toggleOutlineHideNotesCommand(_ sender: Any?) {
		mainSplitViewController?.toggleOutlineHideNotes(sender)
	}

	@objc func expandAllInOutlineCommand(_ sender: Any?) {
		mainSplitViewController?.expandAllInOutline(sender)
	}

	@objc func collapseAllInOutlineCommand(_ sender: Any?) {
		mainSplitViewController?.collapseAllInOutline(sender)
	}

	@objc func expandAllCommand(_ sender: Any?) {
		mainSplitViewController?.expandAll(sender)
	}

	@objc func collapseAllCommand(_ sender: Any?) {
		mainSplitViewController?.collapseAll(sender)
	}

	@objc func expandCommand(_ sender: Any?) {
		mainSplitViewController?.expand(sender)
	}

	@objc func collapseCommand(_ sender: Any?) {
		mainSplitViewController?.collapse(sender)
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
		case #selector(createRowCommand(_:)):
			if mainSplitViewController?.isCreateRowUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(indentRowsCommand(_:)):
			if mainSplitViewController?.isIndentRowsUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(outdentRowsCommand(_:)):
			if mainSplitViewController?.isOutdentRowsUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(toggleCompleteRowsCommand(_:)):
			if mainSplitViewController?.isCompleteRowsAvailable ?? false {
				command.title = L10n.complete
			} else {
				command.title = L10n.uncomplete
			}
			if mainSplitViewController?.isToggleRowCompleteUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(createRowNotesCommand(_:)):
			if mainSplitViewController?.isCreateRowNotesUnavailable ?? true  {
				command.attributes = .disabled
			}
		case #selector(deleteRowNotesCommand(_:)):
			if mainSplitViewController?.isDeleteRowNotesUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(splitRowCommand(_:)):
			if mainSplitViewController?.isSplitRowUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(toggleBoldCommand(_:)), #selector(toggleItalicsCommand(_:)):
			if mainSplitViewController?.isFormatUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(linkCommand(_:)):
			if mainSplitViewController?.isLinkUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(toggleOutlineFilterCommand(_:)):
			if mainSplitViewController?.isOutlineFiltered ?? false {
				command.title = L10n.showCompleted
			} else {
				command.title = L10n.hideCompleted
			}
			if mainSplitViewController?.isOutlineFunctionsUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(toggleOutlineHideNotesCommand(_:)):
			if mainSplitViewController?.isOutlineNotesHidden ?? false {
				command.title = L10n.showNotes
			} else {
				command.title = L10n.hideNotes
			}
			if mainSplitViewController?.isOutlineFunctionsUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(expandAllInOutlineCommand(_:)):
			if mainSplitViewController?.isExpandAllInOutlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(collapseAllInOutlineCommand(_:)):
			if mainSplitViewController?.isCollapseAllInOutlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(expandAllCommand(_:)):
			if mainSplitViewController?.isExpandAllUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(collapseAllCommand(_:)):
			if mainSplitViewController?.isCollapseAllUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(expandCommand(_:)):
			if mainSplitViewController?.isExpandUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(collapseCommand(_:)):
			if mainSplitViewController?.isCollapseUnavailable ?? true {
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
		builder.remove(menu: .openRecent)
		
		// Application Menu
		let appMenu = UIMenu(title: "", options: .displayInline, children: [checkForUpdates])
		builder.insertSibling(appMenu, afterMenu: .about)

		// File Menu
		let archiveMenu = UIMenu(title: "", options: .displayInline, children: [restoreArchiveCommand, archiveLocalCommand])
		builder.insertChild(archiveMenu, atStartOfMenu: .file)

		let importExportMenu = UIMenu(title: "", options: .displayInline, children: [importOPMLCommand, exportMarkdownCommand, exportOPMLCommand])
		builder.insertChild(importExportMenu, atStartOfMenu: .file)

		let newWindowMenu = UIMenu(title: "", options: .displayInline, children: [newWindowCommand])
		builder.insertChild(newWindowMenu, atStartOfMenu: .file)

		let newItemsMenu = UIMenu(title: "", options: .displayInline, children: [newOutlineCommand, newFolderCommand])
		builder.insertChild(newItemsMenu, atStartOfMenu: .file)

		// Edit
		let linkMenu = UIMenu(title: "", options: .displayInline, children: [linkCommand])
		builder.insertSibling(linkMenu, afterMenu: .standardEdit)

		// Format
		builder.remove(menu: .format)
		let formatMenu = UIMenu(title: L10n.format, children: [toggleBoldCommand, toggleItalicsCommand])
		builder.insertSibling(formatMenu, afterMenu: .edit)

		// View Menu
		let expandCollapseMenu = UIMenu(title: "",
										options: .displayInline,
										children: [expandAllInOutlineCommand, expandAllCommand, expandCommand, collapseAllInOutlineCommand, collapseAllCommand, collapseCommand])
		builder.insertChild(expandCollapseMenu, atStartOfMenu: .view)
		let toggleFilterOutlineMenu = UIMenu(title: "", options: .displayInline, children: [toggleOutlineFilterCommand, toggleOutlineHideNotesCommand])
		builder.insertChild(toggleFilterOutlineMenu, atStartOfMenu: .view)
		let toggleSidebarMenu = UIMenu(title: "", options: .displayInline, children: [toggleSidebarCommand])
		builder.insertSibling(toggleSidebarMenu, afterMenu: .toolbar)
		
		// Outline Menu
		let completeMenu = UIMenu(title: "", options: .displayInline, children: [toggleCompleteRowsCommand, createRowNotesCommand, deleteRowNotesCommand])
		let mainOutlineMenu = UIMenu(title: "", options: .displayInline, children: [createRowCommand, splitRowCommand, indentRowsCommand, outdentRowsCommand])
		let outlineMenu = UIMenu(title: L10n.outline, children: [mainOutlineMenu, completeMenu])
		builder.insertSibling(outlineMenu, afterMenu: .view)

	}
	
}

