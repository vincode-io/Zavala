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
		
		menuKeyCommands.append(showPreferences)
		menuKeyCommands.append(beginDocumentSearchCommand)
		menuKeyCommands.append(showOpenQuicklyCommand)
		
		if AccountManager.shared.isSyncAvailable {
			menuKeyCommands.append(syncCommand)
		}

		if !(mainCoordinator?.isOutlineFunctionsUnavailable ?? true) {
			if mainCoordinator?.isOutlineFiltered ?? false {
				menuKeyCommands.append(showCompletedCommand)
			} else {
				menuKeyCommands.append(hideCompletedCommand)
			}
			if mainCoordinator?.isOutlineNotesHidden ?? false {
				menuKeyCommands.append(showNotesCommand)
			} else {
				menuKeyCommands.append(hideNotesCommand)
			}
			menuKeyCommands.append(beginInDocumentSearchCommand)
			menuKeyCommands.append(useSelectionForSearchCommand)
			menuKeyCommands.append(nextInDocumentSearchCommand)
			menuKeyCommands.append(previousInDocumentSearchCommand)
			menuKeyCommands.append(printCommand)
			menuKeyCommands.append(outlineGetInfoCommand)
		}
		
		menuKeyCommands.append(newOutlineCommand)
		menuKeyCommands.append(importOPMLCommand)
		
		if !(mainCoordinator?.isExportOutlineUnavailable ?? true) {
			menuKeyCommands.append(exportMarkdownCommand)
			menuKeyCommands.append(exportOPMLCommand)
		}
		
		menuKeyCommands.append(newWindowCommand)
		menuKeyCommands.append(toggleSidebarCommand)
		
		if !(mainCoordinator?.isInsertRowUnavailable ?? true) {
			menuKeyCommands.append(insertRowCommand)
		}
		
		if !(mainCoordinator?.isCreateRowUnavailable ?? true) {
			menuKeyCommands.append(createRowCommand)
		}
		
		if !(mainCoordinator?.isIndentRowsUnavailable ?? true) {
			menuKeyCommands.append(indentRowsCommand)
		}
		
		if !(mainCoordinator?.isOutdentRowsUnavailable ?? true) {
			menuKeyCommands.append(outdentRowsCommand)
		}
		
		if !(mainCoordinator?.isToggleRowCompleteUnavailable ?? true) {
			if mainCoordinator?.isCompleteRowsAvailable ?? false {
				menuKeyCommands.append(completeRowsCommand)
			} else {
				menuKeyCommands.append(uncompleteRowsCommand)
			}
		}
		
		if !(mainCoordinator?.isCreateRowNotesUnavailable ?? true) {
			menuKeyCommands.append(createRowNotesCommand)
		}

		if !(mainCoordinator?.isDeleteRowNotesUnavailable ?? true) {
			menuKeyCommands.append(deleteRowNotesCommand)
		}

		if !(mainCoordinator?.isExpandAllInOutlineUnavailable ?? true) {
			menuKeyCommands.append(expandAllInOutlineCommand)
		}
		
		if !(mainCoordinator?.isCollapseAllInOutlineUnavailable ?? true) {
			menuKeyCommands.append(collapseAllInOutlineCommand)
		}

		if !(mainCoordinator?.isExpandAllUnavailable ?? true) {
			menuKeyCommands.append(expandAllCommand)
		}
		
		if !(mainCoordinator?.isCollapseAllUnavailable ?? true) {
			menuKeyCommands.append(collapseAllCommand)
		}
		
		if !(mainCoordinator?.isExpandUnavailable ?? true) {
			menuKeyCommands.append(expandCommand)
		}
		
		if !(mainCoordinator?.isCollapseUnavailable ?? true) {
			menuKeyCommands.append(collapseCommand)
		}
		
		if !(mainCoordinator?.isDeleteCompletedRowsUnavailable ?? true) {
			menuKeyCommands.append(deleteCompletedRowsCommand)
		}

		return menuKeyCommands
		#endif
	}
		
	let showPreferences = UIKeyCommand(title: L10n.preferences,
										 action: #selector(showPreferences(_:)),
										 input: ",",
										 modifierFlags: [.command])
	
	#if targetEnvironment(macCatalyst)
	let checkForUpdates = UICommand(title: L10n.checkForUpdates, action: #selector(checkForUpdates(_:)))
	#endif
	
	let syncCommand = UIKeyCommand(title: L10n.sync,
								   action: #selector(syncCommand(_:)),
								   input: "r",
								   modifierFlags: [.command])
	
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
	
	let toggleSidebarCommand = UIKeyCommand(title: L10n.toggleSidebar,
											action: #selector(toggleSidebarCommand(_:)),
											input: "s",
											modifierFlags: [.control, .command])
	
	let insertRowCommand = UIKeyCommand(title: L10n.addRowAbove,
										action: #selector(insertRowCommand(_:)),
										input: "\n",
										modifierFlags: [.shift])
	
	let createRowCommand = UIKeyCommand(title: L10n.addRowBelow,
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
											 input: "-",
											 modifierFlags: [.control])
	
	let deleteRowNotesCommand = UIKeyCommand(title: L10n.deleteNote,
											 action: #selector(deleteRowNotesCommand(_:)),
											 input: "-",
											 modifierFlags: [.control, .shift])
	
	let splitRowCommand = UIKeyCommand(title: L10n.splitRow,
									   action: #selector(splitRowCommand(_:)),
									   input: "\n",
									   modifierFlags: [.shift, .alternate])
	
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
	
	let deleteCompletedRowsCommand = UIKeyCommand(title: L10n.deleteCompletedRows,
									   action: #selector(deleteCompletedRowsCommand(_:)),
									   input: "d",
									   modifierFlags: [.command])
	
	let showReleaseNotesCommand = UICommand(title: L10n.releaseNotes, action: #selector(showReleaseNotesCommand(_:)))
	
	let showGitHubRepositoryCommand = UICommand(title: L10n.gitHubRepository, action: #selector(showGitHubRepositoryCommand(_:)))
	
	let showBugTrackerCommand = UICommand(title: L10n.bugTracker, action: #selector(showBugTrackerCommand(_:)))
	
	let showAcknowledgementsCommand = UICommand(title: L10n.acknowledgements, action: #selector(showAcknowledgementsCommand(_:)))
	
	let showOpenQuicklyCommand = UIKeyCommand(title: L10n.openQuickly,
											  action: #selector(showOpenQuicklyCommand(_:)),
											  input: "o",
											  modifierFlags: [.shift, .command])
	
	let beginDocumentSearchCommand = UIKeyCommand(title: L10n.documentFind,
												  action: #selector(beginDocumentSearchCommand(_:)),
												  input: "f",
												  modifierFlags: [.alternate, .command])
	
	let beginInDocumentSearchCommand = UIKeyCommand(title: L10n.findEllipsis,
													action: #selector(beginInDocumentSearchCommand(_:)),
													input: "f",
													modifierFlags: [.command])
	
	let useSelectionForSearchCommand = UIKeyCommand(title: L10n.useSelectionForFind,
													action: #selector(useSelectionForSearchCommand(_:)),
													input: "e",
													modifierFlags: [.command])
	
	let nextInDocumentSearchCommand = UIKeyCommand(title: L10n.findNext,
												   action: #selector(nextInDocumentSearchCommand(_:)),
												   input: "g",
												   modifierFlags: [.command])
	
	let previousInDocumentSearchCommand = UIKeyCommand(title: L10n.findPrevious,
													   action: #selector(previousInDocumentSearchCommand(_:)),
													   input: "g",
													   modifierFlags: [.shift, .command])
	
	let printCommand = UIKeyCommand(title: L10n.print,
									action: #selector(printCommand(_:)),
									input: "p",
									modifierFlags: [.command])

	// Currently unused because it automatically adds Services menus to my other context menus
	let sendCopyCommand = UICommand(title: L10n.sendCopy,
									action: #selector(sendCopy(_:)),
									propertyList: UICommandTagShare)

	let shareCommand = UICommand(title: L10n.share, action: #selector(shareCommand(_:)))

	let outlineGetInfoCommand = UIKeyCommand(title: L10n.getInfo,
											 action: #selector(outlineGetInfoCommand(_:)),
											 input: "i",
											 modifierFlags: [.control, .command])

	var mainCoordinator: MainCoordinator? {
		return UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController as? MainCoordinator
	}
	
	#if MAC_TEST
	private var crashReporter = CrashReporter()
	#endif
	
	#if targetEnvironment(macCatalyst)
	var appKitPlugin: AppKitPlugin?
	#endif

	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		#if MAC_TEST
		let oldDocumentAccountURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let oldDcumentAccountsFolder = oldDocumentAccountURL.appendingPathComponent("Accounts").absoluteString
		let documentAccountsFolderPath = String(oldDcumentAccountsFolder.suffix(from: oldDcumentAccountsFolder.index(oldDcumentAccountsFolder.startIndex, offsetBy: 7)))
		#else
		let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as! String
		let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
		let documentAccountsFolderPath = containerURL!.appendingPathComponent("Accounts").path
		#endif
		
		AccountManager.shared = AccountManager(accountsFolderPath: documentAccountsFolderPath)
		return true
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		AppDefaults.registerDefaults()

		NotificationCenter.default.addObserver(self, selector: #selector(checkForUserDefaultsChanges), name: UserDefaults.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

		var menuItems = [UIMenuItem]()
		menuItems.append(UIMenuItem(title: L10n.bold, action: .toggleBoldface))
		menuItems.append(UIMenuItem(title: L10n.italic, action: .toggleItalics))
		menuItems.append(UIMenuItem(title: L10n.link, action: .editLink))
		UIMenuController.shared.menuItems = menuItems

		#if targetEnvironment(macCatalyst)
		guard let pluginPath = (Bundle.main.builtInPlugInsPath as NSString?)?.appendingPathComponent("AppKitPlugin.bundle"),
			  let bundle = Bundle(path: pluginPath),
			  let cls = bundle.principalClass as? NSObject.Type,
			  let appKitPlugin = cls.init() as? AppKitPlugin else { return true }
		
		self.appKitPlugin = appKitPlugin
		appKitPlugin.start()
		#endif
		
		UIApplication.shared.registerForRemoteNotifications()
		NSUbiquitousKeyValueStore.default.synchronize()
		
		#if MAC_TEST
		DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
			guard let controller = self.mainCoordinator as? UIViewController else { return }
			self.crashReporter.check(presentingController: controller)
		}
		#endif
		
		return true
	}

	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		DispatchQueue.main.async {
			AccountManager.shared.receiveRemoteNotification(userInfo: userInfo) {
				completionHandler(.newData)
			}
		}
	}
	
	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		if options.userActivities.first?.activityType == NSUserActivity.ActivityType.openEditor.rawValue {
			return UISceneConfiguration(name: "Outline Editor Configuration", sessionRole: connectingSceneSession.role)
		} else {
			return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
		}
	}

	// MARK: Actions

	@objc func showPreferences(_ sender: Any?) {
		#if targetEnvironment(macCatalyst)
		appKitPlugin?.showPreferences()
		#else
		mainCoordinator?.showSettings()
		#endif
	}

	#if targetEnvironment(macCatalyst)
	@objc func checkForUpdates(_ sender: Any?) {
		appKitPlugin?.checkForUpdates()
	}
	#endif

	@objc func syncCommand(_ sender: Any?) {
		AccountManager.shared.sync()
	}

	@objc func importOPMLCommand(_ sender: Any?) {
		mainCoordinator?.importOPML()
	}

	@objc func exportMarkdownCommand(_ sender: Any?) {
		mainCoordinator?.exportMarkdown()
	}

	@objc func exportOPMLCommand(_ sender: Any?) {
		mainCoordinator?.exportOPML()
	}

	@objc func newWindow(_ sender: Any?) {
		let userActivity = NSUserActivity(activityType: NSUserActivity.ActivityType.newWindow.rawValue)
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil, errorHandler: nil)
	}
	
	@objc func createOutlineCommand(_ sender: Any?) {
		mainCoordinator?.createOutline()
	}
	
	@objc func toggleSidebarCommand(_ sender: Any?) {
		if let mainSplitViewController = mainCoordinator as? MainSplitViewController {
			mainSplitViewController.toggleSidebar(sender)
		}
	}
	
	@objc func insertRowCommand(_ sender: Any?) {
		mainCoordinator?.insertRow()
	}
	
	@objc func createRowCommand(_ sender: Any?) {
		mainCoordinator?.createRow()
	}
	
	@objc func indentRowsCommand(_ sender: Any?) {
		mainCoordinator?.indentRows()
	}
	
	@objc func outdentRowsCommand(_ sender: Any?) {
		mainCoordinator?.outdentRows()
	}
	
	@objc func toggleCompleteRowsCommand(_ sender: Any?) {
		mainCoordinator?.toggleCompleteRows()
	}
	
	@objc func createRowNotesCommand(_ sender: Any?) {
		mainCoordinator?.createRowNotes()
	}
	
	@objc func deleteRowNotesCommand(_ sender: Any?) {
		mainCoordinator?.deleteRowNotes()
	}
	
	@objc func splitRowCommand(_ sender: Any?) {
		mainCoordinator?.splitRow()
	}
	
	@objc func toggleBoldCommand(_ sender: Any?) {
		mainCoordinator?.outlineToggleBoldface()
	}
	
	@objc func toggleItalicsCommand(_ sender: Any?) {
		mainCoordinator?.outlineToggleItalics()
	}
	
	@objc func linkCommand(_ sender: Any?) {
		mainCoordinator?.link()
	}

	@objc func toggleOutlineFilterCommand(_ sender: Any?) {
		mainCoordinator?.toggleOutlineFilter()
	}

	@objc func toggleOutlineHideNotesCommand(_ sender: Any?) {
		mainCoordinator?.toggleOutlineHideNotes()
	}

	@objc func expandAllInOutlineCommand(_ sender: Any?) {
		mainCoordinator?.expandAllInOutline()
	}

	@objc func collapseAllInOutlineCommand(_ sender: Any?) {
		mainCoordinator?.collapseAllInOutline()
	}

	@objc func expandAllCommand(_ sender: Any?) {
		mainCoordinator?.expandAll()
	}

	@objc func collapseAllCommand(_ sender: Any?) {
		mainCoordinator?.collapseAll()
	}

	@objc func expandCommand(_ sender: Any?) {
		mainCoordinator?.expand()
	}

	@objc func collapseCommand(_ sender: Any?) {
		mainCoordinator?.collapse()
	}
	
	@objc func deleteCompletedRowsCommand(_ sender: Any?) {
		mainCoordinator?.deleteCompletedRows()
	}
	
	@objc func showReleaseNotesCommand(_ sender: Any?) {
		mainCoordinator?.openURL(AppAssets.releaseNotesURL)
	}

	@objc func showGitHubRepositoryCommand(_ sender: Any?) {
		mainCoordinator?.openURL(AppAssets.githubRepositoryURL)
	}
	
	@objc func showBugTrackerCommand(_ sender: Any?) {
		mainCoordinator?.openURL(AppAssets.bugTrackerURL)
	}
	
	@objc func showAcknowledgementsCommand(_ sender: Any?) {
		mainCoordinator?.openURL(AppAssets.acknowledgementsURL)
	}

	@objc func showOpenQuicklyCommand(_ sender: Any?) {
		if let mainSplitViewController = mainCoordinator as? MainSplitViewController {
			mainSplitViewController.showOpenQuickly()
		}
	}

	@objc func printCommand(_ sender: Any?) {
		mainCoordinator?.printDocument()
	}

	@objc func sendCopy(_ sender: Any?) {
		mainCoordinator?.sendCopy()
	}

	@objc func shareCommand(_ sender: Any?) {
		mainCoordinator?.share()
	}

	@objc func beginDocumentSearchCommand(_ sender: Any?) {
		if let mainSplitViewController = mainCoordinator as? MainSplitViewController {
			mainSplitViewController.beginDocumentSearch()
		}
	}

	@objc func beginInDocumentSearchCommand(_ sender: Any?) {
		mainCoordinator?.beginInDocumentSearch()
	}

	@objc func useSelectionForSearchCommand(_ sender: Any?) {
		mainCoordinator?.useSelectionForSearch()
	}

	@objc func nextInDocumentSearchCommand(_ sender: Any?) {
		mainCoordinator?.nextInDocumentSearch()
	}

	@objc func previousInDocumentSearchCommand(_ sender: Any?) {
		mainCoordinator?.previousInDocumentSearch()
	}
	
	@objc func outlineGetInfoCommand(_ sender: Any?) {
		mainCoordinator?.outlineGetInfo()
	}
	
	// MARK: Validations
	
	override func validate(_ command: UICommand) {
		switch command.action {
		case #selector(syncCommand(_:)):
			if !AccountManager.shared.isSyncAvailable {
				command.attributes = .disabled
			}
		case #selector(exportMarkdownCommand(_:)), #selector(exportOPMLCommand(_:)):
			if mainCoordinator?.isExportOutlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(insertRowCommand(_:)):
			if mainCoordinator?.isInsertRowUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(createRowCommand(_:)):
			if mainCoordinator?.isCreateRowUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(indentRowsCommand(_:)):
			if mainCoordinator?.isIndentRowsUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(outdentRowsCommand(_:)):
			if mainCoordinator?.isOutdentRowsUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(toggleCompleteRowsCommand(_:)):
			if mainCoordinator?.isCompleteRowsAvailable ?? false {
				command.title = L10n.complete
			} else {
				command.title = L10n.uncomplete
			}
			if mainCoordinator?.isToggleRowCompleteUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(createRowNotesCommand(_:)):
			if mainCoordinator?.isCreateRowNotesUnavailable ?? true  {
				command.attributes = .disabled
			}
		case #selector(deleteRowNotesCommand(_:)):
			if mainCoordinator?.isDeleteRowNotesUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(splitRowCommand(_:)):
			if mainCoordinator?.isSplitRowUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(toggleBoldCommand(_:)), #selector(toggleItalicsCommand(_:)):
			if mainCoordinator?.isFormatUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(linkCommand(_:)):
			if mainCoordinator?.isLinkUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(toggleOutlineFilterCommand(_:)):
			if mainCoordinator?.isOutlineFiltered ?? false {
				command.title = L10n.showCompleted
			} else {
				command.title = L10n.hideCompleted
			}
			if mainCoordinator?.isOutlineFunctionsUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(toggleOutlineHideNotesCommand(_:)):
			if mainCoordinator?.isOutlineNotesHidden ?? false {
				command.title = L10n.showNotes
			} else {
				command.title = L10n.hideNotes
			}
			if mainCoordinator?.isOutlineFunctionsUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(expandAllInOutlineCommand(_:)):
			if mainCoordinator?.isExpandAllInOutlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(collapseAllInOutlineCommand(_:)):
			if mainCoordinator?.isCollapseAllInOutlineUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(expandAllCommand(_:)):
			if mainCoordinator?.isExpandAllUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(collapseAllCommand(_:)):
			if mainCoordinator?.isCollapseAllUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(expandCommand(_:)):
			if mainCoordinator?.isExpandUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(collapseCommand(_:)):
			if mainCoordinator?.isCollapseUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(deleteCompletedRowsCommand(_:)):
			if mainCoordinator?.isDeleteCompletedRowsUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(shareCommand(_:)):
			if mainCoordinator?.isShareUnavailable ?? true {
				command.attributes = .disabled
			}
		case #selector(beginInDocumentSearchCommand(_:)),
			 #selector(useSelectionForSearchCommand(_:)),
			 #selector(nextInDocumentSearchCommand(_:)),
			 #selector(previousInDocumentSearchCommand(_:)),
			 #selector(printCommand(_:)):
			if mainCoordinator?.isOutlineFunctionsUnavailable ?? true {
				command.attributes = .disabled
			}
		default:
			break
		}
	}
		
	// MARK: Menu

	#if targetEnvironment(macCatalyst)
	override func buildMenu(with builder: UIMenuBuilder) {
		super.buildMenu(with: builder)

		guard builder.system == UIMenuSystem.main else { return }
		
		builder.remove(menu: .newScene)
		builder.remove(menu: .openRecent)
		
		// Application Menu
		var appMenuCommands = [UICommand]()
		appMenuCommands.append(showPreferences)
		#if MAC_TEST
		appMenuCommands.append(checkForUpdates)
		#endif
		let appMenu = UIMenu(title: "", options: .displayInline, children: appMenuCommands)
		builder.insertSibling(appMenu, afterMenu: .about)
		
		// File Menu
		let syncMenu = UIMenu(title: "", options: .displayInline, children: [syncCommand])
		builder.insertChild(syncMenu, atStartOfMenu: .file)

		let importExportMenu = UIMenu(title: "", options: .displayInline, children: [importOPMLCommand, exportMarkdownCommand, exportOPMLCommand])
		builder.insertChild(importExportMenu, atStartOfMenu: .file)

		let newMenu = UIMenu(title: "", options: .displayInline, children: [newOutlineCommand, newWindowCommand, showOpenQuicklyCommand])
		builder.insertChild(newMenu, atStartOfMenu: .file)

		let shareMenu = UIMenu(title: "", options: .displayInline, children: [shareCommand, printCommand])
		builder.insertChild(shareMenu, atEndOfMenu: .file)

		let getInfoMenu = UIMenu(title: "", options: .displayInline, children: [outlineGetInfoCommand])
		builder.insertChild(getInfoMenu, atEndOfMenu: .file)

		// Edit
		let linkMenu = UIMenu(title: "", options: .displayInline, children: [linkCommand])
		builder.insertSibling(linkMenu, afterMenu: .standardEdit)

		let documentFindMenu = UIMenu(title: "", options: .displayInline, children: [beginDocumentSearchCommand])
		let inDocumentFindMenu = UIMenu(title: "", options: .displayInline, children: [beginInDocumentSearchCommand, nextInDocumentSearchCommand, previousInDocumentSearchCommand])
		let useSelectionMenu = UIMenu(title: "", options: .displayInline, children: [useSelectionForSearchCommand])
		let findMenu = UIMenu(title: L10n.find, children: [documentFindMenu, inDocumentFindMenu, useSelectionMenu])
		builder.insertSibling(findMenu, beforeMenu: .spelling)
		
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
		let completeMenu = UIMenu(title: "", options: .displayInline, children: [toggleCompleteRowsCommand, deleteCompletedRowsCommand, createRowNotesCommand, deleteRowNotesCommand])
		let mainOutlineMenu = UIMenu(title: "", options: .displayInline, children: [insertRowCommand, createRowCommand, splitRowCommand, indentRowsCommand, outdentRowsCommand])
		let outlineMenu = UIMenu(title: L10n.outline, children: [mainOutlineMenu, completeMenu])
		builder.insertSibling(outlineMenu, afterMenu: .view)

		// Help Menu
		builder.replaceChildren(ofMenu: .help, from: { _ in return [showReleaseNotesCommand, showGitHubRepositoryCommand, showBugTrackerCommand, showAcknowledgementsCommand] })
	}
	#endif
	
}

extension AppDelegate {
	
	@objc private func willEnterForeground() {
		checkForUserDefaultsChanges()
		AccountManager.shared.resume()
	}
	
	@objc private func didEnterBackground() {
		AccountManager.shared.suspend()
	}
	
	@objc private func checkForUserDefaultsChanges() {
		let localAccount = AccountManager.shared.localAccount
		
		if AppDefaults.shared.enableLocalAccount != localAccount.isActive {
			if AppDefaults.shared.enableLocalAccount {
				localAccount.activate()
			} else {
				localAccount.deactivate()
			}
		}
		
		let cloudKitAccount = AccountManager.shared.cloudKitAccount
		
		if AppDefaults.shared.enableCloudKit && cloudKitAccount == nil {
			AccountManager.shared.createCloudKitAccount()
		} else if !AppDefaults.shared.enableCloudKit && cloudKitAccount != nil {
			AccountManager.shared.deleteCloudKitAccount()
		}
	}
	
}
